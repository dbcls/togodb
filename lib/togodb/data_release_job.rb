# frozen_string_literal: true

require 'csv'
require 'json'
require 'uri'
require 'open3'
require 'tempfile'

require 'togodb/search/condition_builder'
require 'togodb/db/pgsql'
require 'togodb/string_utils'
require 'togo_mapper/d2rq/ntriples_generator'
require 'togo_mapper/d2rq/ttl_generator'
require 'togo_mapper/d2rq/rdf_xml_generator'

module Togodb
  class DataReleaseJob
    include Togodb::RDF
    include Togodb::DB::Pgsql
    include Togodb::StringUtils

    class PrimaryKeyNotFound < StandardError;
    end

    @queue = Togodb.data_release_queue

    NUM_RECORDS_PER_READ = 10000

    def self.perform(history_id, output_dir, tmp_dir, update_rdf_repository = false)
      begin
        history = TogodbDataReleaseHistory.find(history_id)

        job = Togodb::DataReleaseJob.new(history)
        job.set_variables(output_dir, tmp_dir)
        #history = job.history
        #-->history.search_condition = job.search_conditions
        history.search_condition = nil
        history.status = 'RUNNING'
        history.save!
        job.execute
        history.status = 'SUCCESS'
        history.released_at = Time.now

        if update_rdf_repository
          Resque.enqueue(Togodb::NewRdfRepositoryJob, job.table.name)
        end
      rescue => e
        if history
          history.status = 'ERROR'
          history.message = e.message
        end
        raise e
      ensure
        history&.save
      end
    end

    attr_reader :history, :search_conditions, :table

    def initialize(data_release_history)
      @history = data_release_history
    end

    def set_variables(output_dir, tmp_dir)
      @dataset = TogodbDataset.find(@history.dataset_id)
      @table = TogodbTable.find(@dataset.table_id)
      @model = @table.active_record
      @columns = @dataset.column_list

      # for D2RQ Mapper
      @class_map = ClassMap.where(table_name: @table.name).reorder(id: :desc).first
      @work = Work.find(@class_map.work_id)

      @fasta_seq_column = nil

      @output_dir = output_dir
      @tmp_dir = tmp_dir

      @file_formats = %w(csv json fasta rdf)
      @output_file = {}

      #-->@search_conditions = search_conditions
      @search_conditions = nil

      @pkeys = check_pkey
      @statements = []
    end

    def execute
      export_base

      id_separator_columns = @table.id_separator_columns
      ignore_id_sep_column = !id_separator_columns.empty?

      ntriples_generator = TogoMapper::D2rq::NtriplesGenerator.new(@work, @dataset.name, nil, true, ignore_id_sep_column)
      nt_file_path = ntriples_generator.generate(true)

      if ignore_id_sep_column
        #apply_id_separator(nt_file_path, id_separator_columns)
        add_idsep_column_ntriples(nt_file_path, id_separator_columns)
      end

      turtle_generator = TogoMapper::D2rq::TtlGenerator.new(@work, @dataset.name)
      turtle_generator.convert_from_ntriples(nt_file_path)

      rdfxml_generator = TogoMapper::D2rq::RdfXmlGenerator.new(@work, @dataset.name)
      rdfxml_generator.convert_from_ntriples(nt_file_path)
    end

    def export_base
      csv_tmp_f = tmp_file_path('csv')
      csv_out_f = output_file_path('csv')

      json_tmp_f = tmp_file_path('json')
      json_out_f = output_file_path('json')

      @csv = CSV.open(csv_tmp_f, 'w')
      @json = []

      # FASTA
      generate_fasta = false
      sequence_type_columns = @table.columns.select(&:sequence_type?)
      unless sequence_type_columns.empty?
        generate_fasta = true
        fasta_tmp_f = tmp_file_path('fasta')
        fasta_out_f = output_file_path('fasta')
        @fasta = File.open(fasta_tmp_f, 'w')
        @pk_column_internal_name = @table.pk_column_internal_name
      end

      # CSV header
      @csv << @columns.map(&:name)

      offset = 0
      records = limited_records(offset, NUM_RECORDS_PER_READ)
      until records.empty?
        records.each do |record|
          next if record.nil?

          handle_one_record(record)
        end
        offset += NUM_RECORDS_PER_READ
        records = limited_records(offset, NUM_RECORDS_PER_READ)
      end

      # Version information (for RDF)
      #statements_for_version_info.each do |statement|
      #  rdf << statement
      #end
      #rdf.flush

      @csv.close
      File.rename(csv_tmp_f, csv_out_f)

      File.open(json_tmp_f, 'w') do |f|
        f.puts JSON.pretty_generate(@json)
      end
      File.rename(json_tmp_f, json_out_f)

      return unless generate_fasta

      @fasta.close
      File.rename(fasta_tmp_f, fasta_out_f)
    end

    def search_conditions
      if @dataset.filter_condition.nil? || @dataset.filter_condition.empty?
        conditions = nil
      else
        filter = JSON.parse(@dataset.filter_condition)
        condition_builder = Togodb::Search::ConditionBuilder.new(@table.active_record, false, @table.id)
        conditions = condition_builder.build(filter, @dataset.column_list)
      end

      conditions
    end

    def limited_records(offset, limit)
      @model.where(@search_conditions).order(@pkeys.map { |p| %("#{p}") }.join(',')).offset(offset).limit(limit)
    end

    def output_pkey_values
      conn = ActiveRecord::Base.connection
      tf = Tempfile.new('togodb_data_release', Togodb.temporary_workspace)
      if @search_conditions.kind_of?(Array)
        statement, *values = @search_conditions
        where = statement.gsub('?') { conn.quote values.shift }
      else
        where = @search_conditions
      end

      sql_parts = [%/COPY (SELECT "#{@table.primary_key}" FROM "#{@table.name}"/]
      if where.to_s.strip != ''
        sql_parts << "WHERE #{where}"
      end
      sql_parts << %/ORDER BY "#{@table.primary_key}") TO '#{tf.path}'/
      conn.execute(sql_parts.join(' '))

      tf.close

      tf
    end

    def select_records
      @model.where(conditions: @search_conditions)
    end

    def output_file_name(file_format)
      Togodb::DataRelease.dataset_file_name(@table.name, @dataset.name, file_format)
    end

    def output_file_path(file_format)
      "#{@output_dir}/#{output_file_name(file_format)}"
    end

    def tmp_file_path(file_format)
      "#{@tmp_dir}/#{output_file_name(file_format)}"
    end

    def run_formatdb
      base_db = @output_file['fasta']
      pos = base_db.rindex('.')
      unless pos.nil?
        base_db = base_db[0..pos - 1]
      end
      log_file = "#{base_db}_formatdb.log"

      p_opt = if @fasta_seq_column.other_type == 'DNA_Sequence'
                'F'
              else
                'T'
              end

      system("formatdb -i #{@output_file['fasta']} -n #{base_db} -p #{p_opt} -o T -l #{log_file}")
    end

    private

    def handle_one_record(record)
      @csv_row_data = []
      @json_row_data = {}
      @columns.each do |column|
        handle_one_column(record, column)
      end

      @csv << @csv_row_data
      @json << @json_row_data
    end

    def handle_one_column(record, column)
      col_value = if column['type'] == 'datetime'
                    record[column.internal_name].to_s.split(/ /)[0..1].join(' ')
                  else
                    record[column.internal_name]
                  end

      @csv_row_data << col_value
      @json_row_data[column.name] = col_value

      return unless column.sequence_type?

      @fasta.puts ">#{record[@pk_column_internal_name]} http://#{Togodb.app_server}/entry/#{@table.name}/#{record[@pk_column_internal_name]}"
      seq = record[column.internal_name]
      seq = '' if seq.nil?
      if /\n/ =~ seq
        @fasta.puts seq
      else
        @fasta.puts seq.scan(/.{1,50}/).join("\n")
      end
    end

    def check_pkey
      pkeys = primary_key_infos(@table.name)
      if pkeys.empty?
        raise PrimaryKeyNotFound, 'There is no primary key. A database that does not have a primary key, you will not be able to create the data.'
      end

      pkeys.map { |p| p[:column_name] }
    end

    def add_idsep_column_ntriples(nt_file_path, id_separator_columns)
      File.open(nt_file_path, 'a') do |f|
        @table.active_record.all.each do |record|
          subject = subject_uri(record)
          id_separator_columns.each do |column|
            property_bridge = PropertyBridge.find_by(work_id: @work.id, column_name: column.internal_name)
            predicate_uris_by_property_bridge(property_bridge).each do |predicate|
              property_values_with_idsep(property_bridge, record, column).each do |object|
                f.puts [subject, predicate, object, '.'].join(' ')
              end
            end
          end
        end
      end
    end

    def subject_uri(record)
      subject_config = ClassMapPropertySetting.where(class_map_id: @class_map.id).select(&:subject?).first
      class_map_property = ClassMapProperty.find(subject_config.class_map_property_id)
      case class_map_property.property
      when 'd2rq:uriPattern'
        subject_uri = subject_config.value
        absolute_uri(apply_d2rq_pattern(subject_uri, record))
      when 'd2rq:uriColumn'
        column_name = subject_config.value.split('.', 2).at(1)
        record[column_name]
      end
    end

    def property_value(property_bridge, record)
      pbps = PropertyBridgePropertySetting.where(property_bridge_id: property_bridge.id).select(&:property_value?).first
      if pbps
        property_bridge_property = PropertyBridgeProperty.find(pbps.property_bridge_property_id)
        case property_bridge_property.property
        when 'd2rq:column'
          object_value(pbps, property_raw_value(pbps, record))
        when 'd2rq:pattern'
          object_value(pbps, apply_d2rq_pattern(pbps.value, record))
        when 'd2rq:uriColumn'
          absolute_uri(property_raw_value(pbps, record))
        when 'd2rq:uriPattern'
          absolute_uri(apply_d2rq_pattern(pbps.value, record))
        end
      else
        ''
      end
    end

    def property_values_with_idsep(property_bridge, record, id_separator_column)
      pbps = PropertyBridgePropertySetting.where(property_bridge_id: property_bridge.id).select(&:property_value?).first
      if pbps
        property_bridge_property = PropertyBridgeProperty.find(pbps.property_bridge_property_id)
        case property_bridge_property.property
        when 'd2rq:column'
          property_raw_value(pbps, record).split(compile_id_separator(id_separator_column.id_separator)).map do |v|
            object_value(pbps, v)
          end
        when 'd2rq:pattern'
          apply_d2rq_pattern(pbps.value, record, id_separator_column).map do |v|
            object_value(pbps, v)
          end
        when 'd2rq:uriColumn'
          property_raw_value(pbps, record).split(compile_id_separator(id_separator_column.id_separator)).map do |v|
            if v.start_with?('http')
              absolute_uri("<#{v}>")
            else
              absolute_uri(v)
            end
          end
        when 'd2rq:uriPattern'
          apply_d2rq_pattern(pbps.value, record, id_separator_column).map do |v|
            absolute_uri(v)
          end
        end
      else
        []
      end
    end

    def apply_d2rq_pattern(pattern, record, id_separator_column = nil)
      value = pattern.dup
      tmpl = pattern.dup
      values = []

      while /@@(.+?)@@/ =~ tmpl
        tbl_col = $1
        column_name = tbl_col.split('.', 2).at(1)
        unless column_name.nil?
          if column_name == 'id'
            value = value.gsub("@@#{tbl_col}@@", record['id'].to_s)
          else
            column = TogodbColumn.find_by(table_id: @table.id, name: column_name)
            unless column.nil?
              if id_separator_column.nil? || column.id != id_separator_column.id
                value = value.gsub("@@#{tbl_col}@@", record[column.internal_name].to_s)
              else
                record[column.internal_name].to_s.split(compile_id_separator(id_separator_column.id_separator)).each do |v|
                  values << value.gsub("@@#{tbl_col}@@", v)
                end
              end
            end
          end
        end
        tmpl = $'
      end

      if id_separator_column.nil?
        value
      else
        values
      end
    end

    def predicate_uris_by_property_bridge(property_bridge)
      uris = []

      PropertyBridgePropertySetting.where(
          property_bridge_id: property_bridge.id,
          property_bridge_property_id: PropertyBridgeProperty.predicate_properties.map(&:id)
      ).each do |predicate_setting|
        predicate_uri = predicate_uri_by_property_bridge_property_setting(predicate_setting)
        uris << predicate_uri unless predicate_uri.nil?
      end

      uris
    end

    def predicate_uri_by_property_bridge_property_setting(property_bridge_property_setting)
      predicate = property_bridge_property_setting.value.to_s
      if predicate.empty?
        nil
      else
        absolute_uri(predicate)
      end
    end

    def absolute_uri(uri)
      if /\A<(.+)>\z/ =~ uri
        scheme = $1.split(':/').at(0)
        if scheme.start_with?('http')
          uri
        else
          "<#{Togodb.d2rq_base_uri}#{$1}>"
        end
      else
        prefix, local_part = uri.split(':', 2)
        if prefix.to_s.empty?
          uri
        else
          namespace = Namespace.find_by(id: NamespaceSetting.where(work_id: @work.id).map(&:namespace_id), prefix: prefix)
          if namespace.nil?
            uri
          else
            "<#{namespace.uri}#{local_part}>"
          end
        end
      end
    end

    def object_value(pbps, value)
      v = %Q("#{value}")

      lang = PropertyBridgePropertySetting.for_lang(pbps.id)
      if lang
        v = "#{v}@#{lang.value}"
      else
        datatype = PropertyBridgePropertySetting.for_datatype(pbps.id)
        if datatype
          v = "#{v}^^#{absolute_uri(datatype.value)}"
        end
      end

      v
    end

    def property_raw_value(pbps, record)
      property_bridge_property = PropertyBridgeProperty.find(pbps.property_bridge_property_id)
      case property_bridge_property.property
      when 'd2rq:column', 'd2rq:uriColumn'
        column_name = pbps.value.split('.', 2).at(1)
        if column_name == 'id'
          record['id']
        else
          column = TogodbColumn.find_by(table_id: @table.id, name: column_name)
          if column
            record[column.internal_name]
          else
            ''
          end
        end
      when 'd2rq:pattern', 'd2rq:uriPattern'
        pbps.value
      end
    end

    def compile_id_separator(id_separator)
      if /\A\/(.+)\/(.*)\z/ =~ id_separator
        Regexp.compile(Regexp.escape $1)
      else
        column.id_separator
      end
    end
  end
end

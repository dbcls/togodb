# frozen_string_literal: true

require 'csv'
require 'json'
require 'uri'
require 'open3'
require 'tempfile'
require 'fileutils'
require 'raptor/converter'

module Togodb
  class DataReleaseJob
    include Raptor::Converter
    include Togodb::RDF
    include Togodb::DB::Pgsql
    include Togodb::StringUtils

    class PrimaryKeyNotFound < StandardError; end

    class BaseWriter
      def initialize(file_path)
        @file_path = file_path
        @fh = nil
      end

      def flush
        @fh&.flush
      end

      def close
        @fh&.close
      end
    end

    class CSVWriter < BaseWriter
      def initialize(file_path, columns)
        super(file_path)

        @columns = columns
      end

      def <<(record)
        if @fh.nil?
          @fh = CSV.open(@file_path, 'w')

          # CSV header
          @fh << @columns.map(&:name)
        end

        @fh << record
      end
    end

    class JSONWriter < BaseWriter
      def initialize(file_path)
        super

        @before_obj = ''
        @indent = 2
      end

      def <<(obj)
        if @fh.nil?
          @fh = File.open(@file_path, 'w')
          # @fh.sync = true
          @fh.puts '['
        else
          @fh.puts(",\n")
        end

        _write(obj)
      end

      def close
        return if @fh.nil?

        @fh.puts "\n]"
        @fh.close
      end

      private

      def _write(obj)
        @fh.write _to_json(obj).split("\n").map { |line| "#{_indent}#{line}" }.join("\n")
      end

      def _to_json(obj)
        JSON.pretty_generate(obj)
      end

      def _indent
        ' ' * @indent
      end
    end

    class FASTAWriter < BaseWriter
      def initialize(file_path, table_name, pk_column_name)
        super(file_path)

        @table_name = table_name
        @pk_column_name = pk_column_name
      end

      def <<(sequence)
        @fh = File.open(file_path, 'w') if @fh.nil?

        _write(sequence)
      end

      private

      def _write(sequence)
        return if sequence.to_s.strip.empty?

        @fh.puts ">#{record[@pk_column_name]} http://#{Togodb.app_server}/entry/#{table_name}/#{record[@pk_column_name]}"
        if /\n/ =~ sequence
          @fh.puts sequence
        else
          @fh.puts sequence.scan(/.{1,50}/).join("\n")
        end
      end
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

        Resque.enqueue(Togodb::NewRDFRepositoryJob, job.table.name) if update_rdf_repository
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

      @output_file = {}

      #-->@search_conditions = search_conditions
      @search_conditions = nil

      @pkeys = check_pkey

      setup_writer
    end

    def execute
      generate_non_rdf_files
      generate_rdf_files
      move_to_release_dir
    end

    def generate_non_rdf_files
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

      @csv.close
      @json.close
      @fasta&.close
    end

    def generate_rdf_files
      ntriples_file = generate_ntriples
      generate_turtle(ntriples_file)
      generate_rdfxml(ntriples_file)
    end

    def generate_ntriples
      id_separator_columns = @table.id_separator_columns
      ignore_id_sep_column = !id_separator_columns.empty?

      ntriples_generator = TogoMapper::D2RQ::NtriplesGenerator.new(@work, @dataset.name, nil, true, ignore_id_sep_column)
      ntriples_file_path = ntriples_generator.generate(true)
      puts "----- ntriples -----"
      puts File.read(ntriples_file_path)

      add_idsep_column_ntriples(ntriples_file_path, id_separator_columns) if ignore_id_sep_column

      ntriples_file_path
    end

    def generate_turtle(ntriples_file_path)
      @turtle_file_path = tmp_file_path('ttl')
      convert_by_ntriples(ntriples_file_path, 'ttl', @turtle_file_path, namespace: namespace)
    end

    def generate_rdfxml(ntriples_file_path)
      @rdfxml_file_path = tmp_file_path('rdf')
      convert_by_ntriples(ntriples_file_path, 'rdf', @rdfxml_file_path, namespace: namespace)
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
      sql_parts << "WHERE #{where}" if where.to_s.strip != ''
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
      base_db = base_db[0..pos - 1] unless pos.nil?
      log_file = "#{base_db}_formatdb.log"

      p_opt = if @fasta_seq_column.other_type == 'DNA_Sequence'
                'F'
              else
                'T'
              end

      system("formatdb -i #{@output_file['fasta']} -n #{base_db} -p #{p_opt} -o T -l #{log_file}")
    end

    private

    def setup_writer
      @csv_tmp_f = tmp_file_path('csv')
      @csv = CSVWriter.new(@csv_tmp_f, @columns)

      @json_tmp_f = tmp_file_path('json')
      @json = JSONWriter.new(@json_tmp_f)

      # FASTA
      sequence_type_columns = @table.columns.select(&:sequence_type?)
      @fasta = if sequence_type_columns.empty?
                 nil
               else
                 @fasta_tmp_f = tmp_file_path('fasta')
                 FASTAWriter.new(@fasta_tmp_f, @table.name, @table.pk_column_internal_name)
               end
    end

    def handle_one_record(record)
      csv_row = []
      json_row = {}
      @columns.each do |column|
        column_value = handle_one_column(record, column)
        csv_row << column_value
        json_row[column.name] = column_value
        @fasta << column_value if column.sequence_type?
      end

      @csv << csv_row
      @json << json_row
    end

    def handle_one_column(record, column)
      if column['type'] == 'datetime'
        record[column.internal_name].to_s.split(/ /)[0..1].join(' ')
      else
        record[column.internal_name]
      end
    end

    def move_to_release_dir
      ::FileUtils.move(@csv_tmp_f, output_file_path('csv'))
      ::FileUtils.move(@json_tmp_f, output_file_path('json'))
      ::FileUtils.move(@fasta_tmp_f, output_file_path('fasta')) unless @fasta_tmp_f.nil?

      ::FileUtils.move(@turtle_file_path, output_file_path('ttl'))
      ::FileUtils.move(@rdfxml_file_path, output_file_path('rdf'))
    end

    # def write_fasta(record, column)
    #   @fasta.puts ">#{record[@pk_column_internal_name]} http://#{Togodb.app_server}/entry/#{@table.name}/#{record[@pk_column_internal_name]}"
    #   seq = record[column.internal_name]
    #   seq = '' if seq.nil?
    #   if /\n/ =~ seq
    #     @fasta.puts seq
    #   else
    #     @fasta.puts seq.scan(/.{1,50}/).join("\n")
    #   end
    # end

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
        v = "#{v}^^#{absolute_uri(datatype.value)}" if datatype
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

    def namespace
      if @namespace.nil?
        @namespace = {}
        NamespaceSetting.where(work_id: @work.id).each do |namespace_setting|
          namespace = ::Namespace.find(namespace_setting.namespace_id)
          next if %w[map d2rq jdbc].include?(namespace.prefix)

          @namespace[namespace.prefix.to_sym] = ::RDF::URI.new(namespace.uri)
        end
      end

      @namespace
    end
  end
end

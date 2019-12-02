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
          Resque.enqueue(Togodb::NewRdfRepositoryJob, job.table.id, job.output_file_path('rdf'))
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

      ntriples_generator = TogoMapper::D2rq::NtriplesGenerator.new(@work, @dataset.name)
      nt_file_path = ntriples_generator.generate(true)

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

  end
end

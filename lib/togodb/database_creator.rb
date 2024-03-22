require 'csv'

module Togodb
  module DatabaseCreator
    include Togodb::FileUtils
    include Togodb::StringUtils

    class InvalidTableName < StandardError;
    end
    class DataNotFound < Togodb::ExpectedError;
    end

    def check_database_name(name)
      #if @user.guest_user? && name[0,6] != "guest_"
      #  name = "guest_#{name}"
      #end

      # first, check whether the given table name is valid or not
      unless Togodb.valid_table_name?(name)
        raise InvalidTableName, "Invalid database name '#{name}'."
      end

      if Togodb.reserved_table_name?(name)
        raise InvalidTableName, "Database name '#{name}' is reserved for TogoDB system."
      end

      # then, check confliction with existing tables
      if ActiveRecord::Base.connection.tables.include?(name)
        raise InvalidTableName, "The database '#{name}' already exists. Please specify a different name."
      end

      # lookup ruby classes whether the model class name conflicts or not
      begin
        model = TogodbTable.new(name: name).class_name
        klass = model.constantize
        if klass.is_a?(Class) and klass < ActiveRecord::Base
          # ok. it seems re-importing
        else
          raise InvalidTableName, "'#{name}' conflicts with system name '#{model}'."
        end
      rescue NameError
        # no conflicts
      end
    end

    def parse_for_header_line
      records = []
      n = 0
      CSV.foreach(uploaded_file(@create.file_format), **csv_opts) do |row|
        records << row
        n += 1
        break if n == 3 # we need first three rows at most
      end

      header = records.first # header or one data should be exist
      raise DataNotFound if header.blank?

      records
    end

    def column_name_and_sample_by_file(first_line_is_header)
      column_samples = []

      column_names = []
      column_labels = []
      lines = []
      no = 1
      CSV.foreach(uploaded_file(@create.file_format), **csv_opts) do |row|
        lines << row
        no += 1

        break if no > 3
      end

      if first_line_is_header
        # first line (lines[0]) of CSV file is header line
        lines[0].each_with_index do |first_line_column_value, i|
          column_name = coerce_to_column_name(first_line_column_value, i + 1)
          column_names << column_name
          column_labels << if first_line_column_value == column_name
                             column_name.capitalize
                           else
                             first_line_column_value
                           end
        end
        samples = if lines.size > 1
                    lines[1]
                  else
                    Array.new(column_names.size) { '' }
                  end
      else
        # first line of CSV file is not header line, so generate column names
        column_names = lines[0].size.times.map { |i| "col#{i + 1}" }
        column_labels = column_names.map(&:capitalize)
        samples = lines[0]
      end

      column_names.zip(samples, column_labels).each do |array|
        column_samples << { name: array[0], sample: array[1], label: array[2] }
      end

      column_samples
    end

    def coerce_to_column_name(name, num_unknowns = 1)
      name = name.to_s.strip.underscore.gsub(/[\s_-]+/, '_')
      if Togodb.valid_column_name?(name)
        name
      else
        "col#{num_unknowns}"
      end
    end

    def guess_column_types(column_indexes = nil)
      opts = {
        header: @create.header_line,
        fs: line_separator(@create.file_format),
        csv_file_encoding: @create.input_file_encoding || 'UTF-8'
      }
      Togodb::GuessColumnType.new(@create.uploded_file_path, opts).execute(column_indexes)
    end

    def guess_column_type_simply(name, data)
      return 'string' if /name/ === name.to_s

      case data.to_s
      when /^-?\d+$/ then
        'integer'
      when /^-?\d*\.\d+$/ then
        'float'
      else
        'string'
      end
    end

    def line_separator(format)
      case format
      when 'csv'
        ','
      when 'tsv'
        "\t"
      end
    end

    def uploaded_file(format)
      "#{Togodb.upfile_saved_dir}/create#{@create.id}.#{format}"
    end

    # def utf8_file(format)
    #   "#{Togodb.upfile_saved_dir}/create#{@create.id}-utf8.#{format}"
    # end

    def create_columns
      types = guess_column_types
      columns = []

      @column_samples.each_with_index do |hash, i|
        position = i + 1
        data_type = types[i] || guess_column_type_simply(hash[:name], hash[:sample])
        attr = {
            name: hash[:name],
            internal_name: "col_#{hash[:name]}",
            data_type: data_type,
            label: hash[:label],
            enabled: true,
            sanitize: true,
            position: position,
            action_list: position <= 100,
            action_show: true,
            action_search: data_type == 'string' || data_type == 'text',
            action_luxury: data_type != 'sequence',
            list_disp_order: position,
            show_disp_order: position,
            table_id: @table.id
        }
        columns << TogodbColumn.create(attr)
      end

      columns
    end

    def enqueue_data_import_job
      key = random_str(16)
      Resque.enqueue Togodb::DataImportJob, @create.id, key, @table.csv_cols_for_data_import_job

      key
    end

    def csv_opts
      {
        encoding: "#{@create.input_file_encoding}:UTF-8",
        col_sep: line_separator(@create.file_format),
        liberal_parsing: true
      }
    end
  end
end

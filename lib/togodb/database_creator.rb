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
      CSV.foreach(utf8_file(@create.file_format), encoding: 'UTF-8', col_sep: line_separator(@create.file_format), liberal_parsing: true) do |row|
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
      samples = []
      first_line = []
      second_line = []
      no = 1
      CSV.foreach(utf8_file(@create.file_format), encoding: 'UTF-8', col_sep: line_separator(@create.file_format), liberal_parsing: true) do |row|
        if no == 1
          first_line = row
        elsif no == 2
          second_line = row
        end

        no += 1

        break if no > 3
      end

      if first_line_is_header
        first_line.each_with_index do |name, i|
          column_names << coerce_to_column_name(name, i + 1)
        end
        samples = second_line
      else
        column_names = first_line.size.times.map { |i| "col#{i + 1}" }
        samples = first_line
      end

      column_names.zip(samples).each do |array|
        column_samples << { name: array[0], sample: array[1] }
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
      Togodb::GuessColumnType.new(
          @create.utf8_file_path, header: @create.header_line, fs: line_separator(@create.file_format)
      ).execute(column_indexes)
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

    def utf8_file(format)
      "#{Togodb.upfile_saved_dir}/create#{@create.id}-utf8.#{format}"
    end

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
            label: hash[:name].capitalize,
            enabled: true,
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
  end
end

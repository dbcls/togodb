module MetaStanza
  class DataGenerator
    include Togodb::StringUtils
    include MetaStanza::MixIn

    def initialize(togodb_table)
      @togodb_table = togodb_table
    end

    def hash_for_entry_data(row, togodb_columns: @togodb_table.columns)
      hash = {}
      togodb_columns.each do |togodb_column|
        hash.merge!(hash_for_column_data(row, togodb_column))
      end

      hash
    end

    def hash_for_column_data(row, togodb_column)
      hash = {
        togodb_column.name => row[togodb_column.internal_name]
      }

      if togodb_column.has_link?
        hash[metastanza_column_link_attr_key(togodb_column.name)] =
          replace_colname_to_value(togodb_column.html_link_prefix, row, @togodb_table.columns)
      end

      hash
    end
  end
end

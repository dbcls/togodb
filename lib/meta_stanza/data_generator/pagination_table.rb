# frozen_string_literal: true

module MetaStanza
  class DataGenerator
    class PaginationTable < MetaStanza::DataGenerator
      include MetaStanza::MixIn

      def initialize(togodb_table)
        super

        @togodb_columns = @togodb_table.columns.where(enabled: true)
      end

      def generate
        records = []
        @togodb_table.active_record.all.each do |row|
          records << show_link_hash(row).merge(hash_for_entry_data(row, togodb_columns: @togodb_columns))
        end

        records
      end

      def show_link_hash(row)
        {
          MetaStanza::ENTRY_COLUMN_NAME => 'Show',
          metastanza_column_link_attr_key(MetaStanza::ENTRY_COLUMN_NAME) => "#{Togodb.togodb_base_url}/entry/#{@togodb_table.name}/#{row.id}"
        }
      end
    end
  end
end

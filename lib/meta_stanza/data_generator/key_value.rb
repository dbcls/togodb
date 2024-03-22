# frozen_string_literal: true

module MetaStanza
  class DataGenerator
    class KeyValue < MetaStanza::DataGenerator
      def initialize(togodb_table)
        super

        @togodb_columns = @togodb_table.columns_for_entry
      end

      def generate(entry_id)
        row = @togodb_table.active_record.find(entry_id)

        [hash_for_entry_data(row, togodb_columns: @togodb_columns)]
      rescue ActiveRecord::RecordNotFound
        []
      end
    end
  end
end

module Togodb
class DataImportJob
  @queue = Togodb.data_import_queue

  class << self

    def perform(create_id, cache_key, csv_cols)
      data_importer = Togodb::DataImporter.new(create_id, cache_key, csv_cols)
      data_importer.import
    end

  end

end
end

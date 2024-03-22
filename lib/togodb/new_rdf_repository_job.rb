require 'fileutils'
require 'uri'
require 'graphdb/rest'

module Togodb
  class NewRDFRepositoryJob
    @queue = Togodb.new_rdf_repository_queue

    def self.perform(database_name)
      copy_file_for_import(database_name)

      graphdb_uri = URI.parse(Togodb.graphdb_server)
      graphdb = Graphdb::Rest.new(graphdb_uri.host, graphdb_uri.port, graphdb_uri.scheme == 'https')
      if graphdb.exist_repository?(database_name)
        graphdb.delete_repository(database_name)
      end
      graphdb.create_repository(database_name)

      graphdb.import_rdf(database_name)
    end

    def self.copy_file_for_import(database_name)
      src_file = "#{Togodb.dataset_dir}/#{database_name}_default.ttl"
      dst_dir = "#{ENV['HOME']}/graphdb-import"
      ::FileUtils.cp(src_file, dst_dir)
    end
  end
end

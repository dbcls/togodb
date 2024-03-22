require 'erb'
require 'uri'
require 'net/http'

module Graphdb
  class Rest
    def initialize(server_host, server_port = 7200, use_ssl = false)
      @server_host = server_host
      @server_port = server_port
      @use_ssl = use_ssl
    end

    def repository_ids
      http = http_client

      headers = {
          'Accept' => 'application/json'
      }
      response = http.get(repositories_uri_path, headers)
      repositories = JSON.parse(response.body)

      repositories.map{ |repository| repository['id'] }
    end

    def create_repository(database_name)
      repository_id = repository_id_by_database_name(database_name)
      repository_title = repository_title(database_name)
      post_data = ERB.new(File.read(__dir__ + '/config/create_repository.json.erb')).result(binding)

      http = http_client
      headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
      }
      response = http.post(repositories_uri_path, post_data, headers)

      case response.code
      when '200'
      end
    end

    def import_rdf(database_name)
      repository_id = repository_id_by_database_name(database_name)
      post_data = ERB.new(File.read(__dir__ + '/config/import_rdf.json.erb')).result(binding)

      http = http_client
      headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-GraphDB-Repository' => repository_id
      }
      response = http.post(import_rdf_uri_path(repository_id), post_data, headers)

      case response.code
      when '200'
      end
    end

    def importing_status(database_name)
      http = http_client
      headers = {
          'Accept' => 'application/json'
      }
      response = http.get(import_rdf_uri_path(repository_id_by_database_name(database_name)), headers)
      json = JSON.parse(response.body)

      json.select{ |info| info["name"] == "#{database_name}_default.ttl" }.first
    end

    def delete_statements(database_name)
      http = http_client
      headers = {
          'Accept' => 'application/json'
      }
      response = http.delete(repository_statements_uri_path(repository_id_by_database_name(database_name)), headers)

      case response.code
      when '204'
      when '500'

      end
    end

    def delete_repository(database_name)
      http = http_client
      #headers = {
      #    'Accept' => 'application/json'
      #}
      #response = http.delete(rdf4j_repository_uri_path(repository_id_by_database_name(database_name)), headers)
      response = http.delete(repositories_uri_path(repository_id_by_database_name(database_name)))
      case response.code
      when '200'
      when '204'
      when '500'

      end
    end

    def sparql_query(database_name, query, response_type)
      case response_type
      when 'json'
        accept_content_type = 'application/sparql-results+json'
      when 'xml'
        accept_content_type = 'application/sparql-results+xml'
      when 'table'
        accept_content_type = 'application/x-binary-rdf-results-table'
      when 'csv'
        accept_content_type = 'text/csv'
      when 'tsv'
        accept_content_type = 'text/tab-separated-values'
      when 'text'
        accept_content_type = 'text/csv'
      else
        accept_content_type = 'application/sparql-results+json'
      end

      http = http_client
      headers = {
          'Accept' => accept_content_type
      }

      url_path = rdf4j_repository_uri_path(repository_id_by_database_name(database_name))
      url_query = URI.encode_www_form([['query', query]])

      response = http.get("#{url_path}?#{url_query}", headers)
      case response.code
      when '200'
        response.body
      when '400'
        response.body
      when '500'
        response.body
      end
    end

    def exist_repository?(database_name)
      repository_ids.include?(repository_id_by_database_name(database_name))
    end

    def repository_id_by_database_name(database_name)
      "togodb-#{database_name}"
    end

    def repository_title(database_name)
      "TogoDB: #{database_name} database"
    end

    private

    def http_client
      http = Net::HTTP.new(@server_host, @server_port)
      http.use_ssl = @use_ssl
      http.read_timeout = 300

      http
    end

    def uri_scheme
      @use_ssl ? 'https' : 'http'
    end

    def repositories_uri_path(repository_id = nil)
      path = '/rest/repositories'
      path = "#{path}/#{repository_id}" unless repository_id.nil?

      path
    end

    def import_rdf_uri_path(repository_id)
      # GraphDB 9.x
      # "/rest/data/import/server/#{repository_id}"

      # GraphDB 10.x
      "/rest/repositories/#{repository_id}/import/server"
    end

    def rdf4j_repository_uri_path(repository_id)
      "/repositories/#{repository_id}"
    end

    def repository_statements_uri_path(repository_id)
      "/repositories/#{repository_id}/statements"
    end
  end
end

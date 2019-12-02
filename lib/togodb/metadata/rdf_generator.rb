require 'tempfile'
require 'rdf/ntriples'

module Togodb
  class Metadata
    class RDFGenerator

      def initialize(metadata, pubmeds, dois)
        @metadata = metadata
        @pubmeds = pubmeds
        @dois = dois
        @table = TogodbTable.find(@metadata.table_id)
      end

      def generate(format = nil)
        rdf = ''

        begin
          prepare

          # Resource class
          statements_for_resource_class.each do |statement|
            @writer << statement
          end

          # SPARQL endpoint
          statements_for_sparql_endpoint.each do |statement|
            @writer << statement
          end

          # Title
          statements_for_title.each do |statement|
            @writer << statement
          end

          # Description
          statements_for_description.each do |statement|
            @writer << statement
          end

          # Creator
          statements_for_creator.each do |statement|
            @writer << statement
          end

          # License
          statements_for_license.each do |statement|
            @writer << statement
          end

          # Literature reference
          statements_for_reference.each do |statement|
            @writer << statement
          end

          @writer.flush
          @temp_file.close

          if format
            require 'open3'
            f_opt = @namespace.keys.map { |p| %Q(-f 'xmlns:#{p}="#{@namespace[p]}"') }.join(' ')
            cmd = "rapper #{f_opt} -i ntriples -o #{format} #{@temp_file.path}"
            stdout, stderr, status = Open3.capture3(cmd)
            rdf = stdout if status.success?
          else
            rdf = File.read(@temp_file.path)
          end
        ensure
          if @temp_file
            @temp_file.close
            @temp_file.unlink
          end
        end

        rdf
      end

      def prepare
        @namespace = {
            rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
            dc: 'http://purl.org/dc/elements/1.1/',
            dcterms: 'http://purl.org/dc/terms/',
            sd: 'http://www.w3.org/ns/sparql-service-description#',
            void: 'http://rdfs.org/ns/void#'
        }

        @temp_file = Tempfile.new('metadata-rdf', Togodb.tmp_dir)
        @writer = RDF::Writer.for(:ntriples).new(@temp_file)
        @resource_uri = RDF::URI(resource_uri)
      end

      def statements_for_resource_class
        [
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF.type,
                           RDF::URI(abs_uri('void', 'Dataset'))),
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF.type,
                           RDF::URI(abs_uri('sd', 'Dataset')))
        ]
      end

      def statements_for_sparql_endpoint
        [
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF::URI(abs_uri('void', 'sparqlEndpoint')),
                           RDF::URI(sparql_endpoint_url))
        ]
      end

      def statements_for_title
        [
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF::URI(abs_uri('dcterms', 'title')),
                           RDF::Literal(@metadata.title))
        ]
      end

      def statements_for_description
        [
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF::URI(abs_uri('dcterms', 'description')),
                           RDF::Literal(@metadata.description))
        ]
      end

      def statements_for_creator
        [
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF::URI(abs_uri('dcterms', 'creator')),
                           RDF::Literal(@metadata.creator))
        ]
      end

      def statements_for_license
        if @metadata.creative_commons.nil? || @metadata.creative_commons == 0
          object = RDF::Literal(@metadata.licence.to_s)
        else
          case @metadata.creative_commons
          when 1
            object = RDF::URI('http://creativecommons.org/licenses/by/3.0/')
          when 2
            object = RDF::URI('http://creativecommons.org/licenses/by-nd/3.0/')
          when 3
            object = RDF::URI('http://creativecommons.org/licenses/by-sa/3.0/')
          when 4
            object = RDF::URI('http://creativecommons.org/licenses/by-nc/3.0/')
          when 5
            object = RDF::URI('http://creativecommons.org/licenses/by-nc-nd/3.0/')
          when 6
            object = RDF::URI('http://creativecommons.org/licenses/by-nc-sa/3.0/')
          end
        end

        [
            RDF::Statement(RDF::URI(@resource_uri),
                           RDF::URI(abs_uri('dcterms', 'license')),
                           object)
        ]
      end

      def statements_for_reference
        statements = []

        unless @metadata.literature_reference.to_s.strip.empty?
          statements << RDF::Statement(RDF::URI(@resource_uri),
                                       RDF::URI(abs_uri('dc', 'references')),
                                       RDF::Literal(@metadata.literature_reference))
        end

        unless @metadata.pubmed.to_s.strip.empty?
          statements << RDF::Statement(RDF::URI(@resource_uri),
                                       RDF::URI(abs_uri('dc', 'references')),
                                       RDF::URI(pubmed_uri(@metadata.pubmed)))
        end
        @pubmeds.each do |pubmed|
          statements << RDF::Statement(RDF::URI(@resource_uri),
                                       RDF::URI(abs_uri('dc', 'references')),
                                       RDF::URI(pubmed_uri(pubmed.pubmed_id.to_s)))
        end

        unless @metadata.doi.to_s.strip.empty?
          statements << RDF::Statement(RDF::URI(@resource_uri),
                                       RDF::URI(abs_uri('dc', 'references')),
                                       RDF::URI(doi_uri(@metadata.doi)))
        end
        @dois.each do |doi|
          statements << RDF::Statement(RDF::URI(@resource_uri),
                                       RDF::URI(abs_uri('dc', 'references')),
                                       RDF::URI(doi_uri(doi.doi)))
        end

        statements
      end

      def resource_uri
        "http://#{Togodb.app_server}/db/#{@table.name}"
      end

      def sparql_endpoint_url
        "http://#{Togodb.app_server}/sparql/#{@table.name}"
      end

      def abs_uri(prefix, v)
        "#{@namespace[prefix.to_sym]}#{v}"
      end

      def pubmed_uri(pubmed_id)
        data_type = Togodb::ColumnTypes.supported_types.select { |hash| hash[:name] == 'PubMed' }[0]
        data_type[:link].gsub('{id}', pubmed_id)
      end

      def doi_uri(doi)
        doi = doi.gsub(/\Adoi\:\s*/, '')
        data_type = Togodb::ColumnTypes.supported_types.select { |hash| hash[:name] == 'DOI' }[0]
        data_type[:link].gsub('{id}', doi)
      end

    end
  end
end

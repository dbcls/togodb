require 'togo_mapper/d2rq/rdf_generator'

module TogoMapper
  module D2rq
    class RdfXmlGenerator < RdfGenerator

      def dump_rdf_format
        'RDF/XML-ABBREV'
      end

      def rapper_format
        'rdfxml-abbrev'
      end

      def file_ext
        'rdf'
      end

    end
  end
end

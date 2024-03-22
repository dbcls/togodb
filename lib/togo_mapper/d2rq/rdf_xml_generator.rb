module TogoMapper
  module D2RQ
    class RDFXmlGenerator < RDFGenerator

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

module TogoMapper
  module D2RQ
    class TtlGenerator < RDFGenerator

      def dump_rdf_format
        'TURTLE'
      end

      def rapper_format
        'turtle'
      end

      def file_ext
        'ttl'
      end

    end
  end
end

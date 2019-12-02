require 'togo_mapper/d2rq/rdf_generator'

module TogoMapper
  module D2rq
    class TtlGenerator < RdfGenerator

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

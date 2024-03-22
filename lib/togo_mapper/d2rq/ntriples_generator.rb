require 'togo_mapper/d2rq/rdf_generator'

module TogoMapper
  module D2RQ
    class NtriplesGenerator < RDFGenerator

      def dump_rdf_format
        'N-TRIPLE'
      end

      def file_ext
        'nt'
      end

    end
  end
end

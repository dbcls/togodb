module TogoMapper
  module D2rq
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

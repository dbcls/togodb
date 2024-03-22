# frozen_string_literal: true

require 'raptor/rapper_error'

module Raptor
  FORMART_NTRIPLES = 'ntriples'
  FORMAT_TURTLE = 'turtle'
  FORMART_RDFXML = 'rdfxml-abbrev'

  module Converter
    def convert(infile_format, infile_path, outfile_format, outfile_path, namespace: {})
      stdout, stderr, status =
        Open3.capture3(
          rapper_cmd(infile_format, infile_path, outfile_format, outfile_path, namespace: namespace)
        )

      raise RapperError, stderr unless status.success?

      stdout
    end

    def convert_by_ntriples(infile_path, outfile_format, outfile_path, namespace: {})
      convert(FORMART_NTRIPLES, infile_path, outfile_format, outfile_path, namespace: namespace)
    end

    def ntriples2turtle(infile_path, outfile_path, namespace: {})
      convert(FORMART_NTRIPLES, infile_path, FORMAT_TURTLE, outfile_path, namespace: namespace)
    end

    def ntriples2rdfxml(infile_path, outfile_path, namespace: {})
      convert(FORMART_NTRIPLES, infile_path, FORMART_RDFXML, outfile_path, namespace: namespace)
    end

    private

    def rdf_format_for_rapper(format)
      case format
      when 'rdf'
        FORMART_RDFXML
      when 'ttl'
        FORMAT_TURTLE
      else
        format
      end
    end

    def rapper_cmd(infile_format, infile_path, outfile_format, outfile_path, namespace: {})
      cmd = [
        Togodb.rapper_path,
        f_option(namespace: namespace),
        '-i',
        rdf_format_for_rapper(infile_format),
        '-o',
        rdf_format_for_rapper(outfile_format),
        infile_path
      ].join(' ')

      "#{cmd} > #{outfile_path}"
    end

    def f_option(namespace: {})
      namespace.keys.map { |prefix| %(-f 'xmlns:#{prefix}="#{@namespace[prefix]}"') }.join(' ')
    end
  end
end

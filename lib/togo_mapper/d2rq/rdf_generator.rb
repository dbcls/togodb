require 'open3'
require 'tempfile'
require 'fileutils'
require 'togodb/data_release'
require 'togo_mapper/d2rq/mapping_generator'

module TogoMapper
  module D2RQ
    class RDFGenerator
      class D2RQDumpError < StandardError;
      end
      class RapperError < StandardError;
      end

      include Togodb::StringUtils

      def initialize(work, dataset_name = nil, result_size_limit = nil, serve_vocabulary = true, ignore_idsep_column = false)
        @work = work
        @db_conn = DBConnection.find_by(work_id: @work.id)

        @dataset_name = if dataset_name.nil?
                          random_str(16)
                        else
                          dataset_name
                        end

        @result_size_limit = result_size_limit
        @serve_vocabulary = serve_vocabulary
        @ignore_idsep_column = ignore_idsep_column

        @namespace = {}
        NamespaceSetting.where(work_id: work.id).each do |namespace_setting|
          namespace = ::Namespace.find(namespace_setting.namespace_id)
          next if %w(map d2rq jdbc).include?(namespace.prefix)

          @namespace[namespace.prefix.to_sym] = ::RDF::URI.new(namespace.uri)
        end
      end

      def generate(use_tempfile_library = false)
        mapping_file_path = generate_mapping_file
        if use_tempfile_library
          tempfile = Tempfile.new(%W(rdf_generator_#{@work.name}_#{@dataset_name} .#{file_ext}), Togodb.tmp_dir)
          output_file_path = tempfile.path
        else
          output_file_path = Togodb::DataRelease.tmp_file_path(@work.name, @dataset_name, 'nt')
        end
        cmd = dump_rdf_cmd(mapping_file_path, output_file_path, dump_rdf_format)
        stdout, stderr, status = Open3.capture3(cmd)

        output_file_path
      end

      def generate_nt
        mapping_file_path = generate_mapping_file
        output_file_path = Togodb::DataRelease.tmp_file_path(@work.name, @dataset_name, 'nt')
        cmd = dump_rdf_cmd(mapping_file_path, output_file_path, 'N-TRIPLE')
        stdout, stderr, status = Open3.capture3(cmd)

        if stderr.blank?
          output_file_path
        else
          raise D2RQDumpError, stderr
        end
      end

      def generate_via_nt(nt_file_path = nil)
        nt_file_path = generate_nt if nt_file_path.nil?

        convert_from_ntriples(nt_file_path)
      end

      def generate_mapping_file
        mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
        mapping_generator.ignore_idsep_column = @ignore_idsep_column

        unless @result_size_limit.nil?
          mapping_generator.database_property = {
              'resultSizeLimit' => @result_size_limit
          }
        end

        mapping_generator.configuration_property = {
            'serveVocabulary' => @serve_vocabulary
        }

        mapping_generator.prepare_by_work(@work)
        mapping_generator.password = @db_conn.decrypt_password

        Tempfile.open(["d2rq-mapping-#{@work.name}", '.ttl'], Togodb.tmp_dir) do |fp|
          fp.print mapping_generator.generate
          fp.path
        end
      end

      def convert_from_ntriples(infile)
        tmp_f = Togodb::DataRelease.tmp_file_path(@work.name, @dataset_name, file_ext)
        out_f = Togodb::DataRelease.output_file_path(@work.name, @dataset_name, file_ext)
        rapper_f_opt = @namespace.keys.map { |p| %Q(-f 'xmlns:#{p}="#{@namespace[p]}"') }.join(' ')

        rapper_o_opt = case file_ext
                       when 'rdf'
                         'rdfxml-abbrev'
                       when 'ttl'
                         'turtle'
                       else
                         file_ext
                       end

        cmd = "cd #{File.dirname(tmp_f)}; #{Togodb.rapper_path} #{rapper_f_opt} -i ntriples -o #{rapper_o_opt} #{infile} > #{tmp_f}"
        stdout, stderr, status = Open3.capture3(cmd)
        if status.success?
          # File.rename(tmp_f, out_f)
          ::FileUtils.move(tmp_f, out_f)
        else
          raise RapperError, stderr
        end

        out_f
      end

      def dump_rdf_cmd(mapping_file_path, output_file_path, format)
        "#{TogoMapper.dump_rdf} -format #{format} -b #{base_uri} -o #{output_file_path} #{mapping_file_path}"
      end

      def base_uri
        Togodb.d2rq_base_uri
      end

      def dump_rdf_format
        'N-TRIPLE'
      end

      def rapper_format
        'ntriples'
      end

    end
  end
end

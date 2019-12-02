require 'fileutils'
require 'zip'
require 'json'
require 'togodb/file_utils'

module Togodb
  class ZipHandler
    include Togodb::FileUtils

    def initialize; end

    def unzip(zip_file, dst_dir)
      Zip::File.foreach(zip_file) do |entry|
        file_path = dst_dir + '/' + encode_file_path(entry.name)
        dirname = File.dirname(file_path)
        ::FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
        entry.extract(file_path)
      end
    end

    def to_json(zip_file, table_name, opts = {})
      prepare_to_json

      Zip::File.foreach(zip_file) do |zip_entry|
        # zip_entry is instance of Zip::Entry
        path_parts = encode_file_path(zip_entry.name).split('/')
        handle_entry(zip_entry, path_parts, opts.merge(table_name: table_name))
      end

      node_maps_to_json(opts.key?(:pretty) ? opts[:pretty] : false)
    end

    def contents(zip_file)
      Zip::File.foreach(zip_file) do |zip_entry|
        puts zip_entry.name
        puts zip_entry.ftype.class
      end
    end

    private

    def regist_directories(zip_entry, path_parts, opts = {})
      names = []
      path_parts.each do |name|
        names << name
        dir_path = names.join('/')
        unless @dir_paths.include?(names.join('/'))
          @dir_paths << dir_path
          dupped_path_parts = names.dup
          node_name = dupped_path_parts.pop
          handle_node(initial_node_hash(node_name), dupped_path_parts)
        end
      end
    end

    def handle_file(zip_entry, path_parts, opts = {})
      node_name = path_parts.pop

      # Since the file name was poped from the path_parts,
      # the elements of the path_parts are directory names.
      regist_directories(zip_entry, path_parts)

      node = initial_node_hash(node_name)
      base_url =
          if path_parts.size.zero?
            "#{opts[:app_server]}/files/#{opts[:table_name]}"
          else
            "#{opts[:app_server]}/files/#{opts[:table_name]}/#{path_parts.join('/')}"
          end

      node[:url] = if node[:name][0, 1] == '/'
                     "#{base_url}#{node[:name][1..-1]}"
                   else
                     "#{base_url}/#{node[:name]}"
                   end
      handle_node(node, path_parts)
    end

    def handle_entry(zip_entry, path_parts, opts = {})
      case zip_entry.ftype.to_s
      when 'directory'
        regist_directories(zip_entry, path_parts, opts)
      when 'file'
        handle_file(zip_entry, path_parts, opts)
      end
    end

    def handle_node(node, path_parts)
      node_maps_id = path_parts.size
      (path_parts.size - @node_maps.size + 1).times do
        @node_maps << {}
      end

      key = path_parts.join('/')
      unless @node_maps[node_maps_id].key?(key)
        @node_maps[node_maps_id][key] = []
      end
      @node_maps[node_maps_id][key] << node

      @node_id += 1
    end

    def initial_node_hash(name)
      {
          name: name,
          id: @node_id,
          children: [],
          url: nil,
          state: { opened: true, selected: false }
      }
    end

    def node_maps_to_json(pretty = false)
      add_node_children

      node_maps = @node_maps[0]['']
      if pretty
        JSON.pretty_generate(node_maps)
      else
        JSON.generate(node_maps)
      end
    end

    def add_node_children
      @node_maps.each_with_index do |hash, i|
        hash.keys.each do |key|
          hash[key].each do |child|
            next unless child.key?(:children) && !@node_maps[i + 1].nil?

            child[:children] = if key == ''
                                 @node_maps[i + 1][child[:name]]
                               else
                                 @node_maps[i + 1]["#{key}/#{child[:name]}"]
                               end
          end
        end
      end
    end

    def prepare_to_json
      @node_id = 1
      @dir_paths = []
      @node_maps = [{ '' => [] }]
      @unshift_name = nil
    end
  end
end

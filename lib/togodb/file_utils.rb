require 'fileutils'
require 'open3'

module Togodb::FileUtils

  def copy_file(src_path, dst_path)
    stdout, stderr, status = Open3.capture3('cp', src_path, dst_path)
    return if status.success?

    ret = File.link(src_path, dst_path)
    FileUtils.cp(src_path, dst_path) unless ret.zero?
  end

  def convert_to_utf8(src_path, dst_path)
    cmd = "#{Togodb.nkf_path} -w -Lu #{src_path} > #{dst_path}"
    stdout, stderr, status = Open3.capture3(cmd)
  end

  def file_format_by_file(file_path)
    file_path[file_path.rindex('.') + 1..-1]
  rescue
    ''
  end

  def list_files(target_dir)
    dirs = []
    files = []
    Dir.foreach(target_dir) do |v|
      next if %w[. ..].include?(v)

      path = "#{target_dir}/#{v}"
      if FileTest.directory?(path)
        dirs << v
      elsif FileTest.file?(path)
        files << v
      end
    end

    { dirs: dirs.sort, files: files.sort }
  end

  def encode_file_path(path)
    require 'nkf'

    from_encoding = NKF.guess(path)
    if from_encoding != 'US-ASCII' && from_encoding != 'UTF-8'
      path.encode(Encoding::UTF_8, from_encoding)
    else
      path
    end
  end

end

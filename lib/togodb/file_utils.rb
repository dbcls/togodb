require 'fileutils'
require 'open3'

module Togodb::FileUtils
  include Togodb::StringUtils

  def copy_file(src_path, dst_path)
    cmd_name = if Togodb.os_is_window?
                 'copy'
               else
                 'cp'
               end
    stdout, stderr, status = Open3.capture3(cmd_name, src_path, dst_path)
    return if status.success?

    FileUtils.cp(src_path, dst_path)
    # begin
    #   ret = File.link(src_path, dst_path)
    # ensure
    #   FileUtils.cp(src_path, dst_path) unless ret.zero?
    #end
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

  def detect_char_code(path)
    if utf8_file?(path)
      'UTF-8'
    elsif shift_jis_file?(path)
      'Windows-31J'
    elsif euc_file?(path)
      'EUC-JP'
    elsif iso_2022_jp_file?(path)
      'ISO_2022_JP'
    else
      'Unknown'
    end
  end

  def utf8_file?(path)
    file_is_utf8 = true
    File.foreach(path) do |line|
      unless utf8?(line)
        file_is_utf8 = false
        break
      end
    end

    file_is_utf8
  end

  def shift_jis_file?(path)
    file_is_shift_jis = true
    File.foreach(path) do |line|
      unless shift_jis?(line)
        file_is_shift_jis = false
        break
      end
    end

    file_is_shift_jis
  end

  def euc_file?(path)
    file_is_euc = true
    File.foreach(path) do |line|
      unless euc?(line)
        file_is_euc = false
        break
      end
    end

    file_is_euc
  end

  def iso_2022_jp_file?(path)
    file_is_iso_2022_jp = true
    File.foreach(path) do |line|
      unless iso_2022_jp?(line)
        file_is_iso_2022_jp = false
        break
      end
    end

    file_is_iso_2022_jp
  end
end

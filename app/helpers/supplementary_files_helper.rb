module SupplementaryFilesHelper

  def supplementary_file_list_link(supplementary_file_id, dir_path)
    if dir_path.blank? || dir_path[0, 1] == '/'
      "/supplementary_files/#{supplementary_file_id}#{dir_path}"
    else
      "/supplementary_files/#{supplementary_file_id}/#{dir_path}"
    end
  end

  def supplementary_file_dl_link(table_name, file_path)
    "/files/#{table_name}/#{file_path}"
  end

  def parent_dir_path(dir_path)
    if dir_path[-1, 1] == '/'
      pos = dir_path[0..-2].rindex('/')
      if pos.nil?
        ''
      else
        dir_path[0..pos - 1]
      end
    else
      pos = dir_path.rindex('/')
      if pos.nil?
        ''
      else
        dir_path[0..pos]
      end
    end

  end

end

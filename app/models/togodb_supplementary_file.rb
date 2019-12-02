require 'fileutils'

class TogodbSupplementaryFile < ApplicationRecord
  belongs_to :togodb_table

  alias :table :togodb_table

  before_create :create_base_dir
  before_destroy :delete_base_dir

  def exist_zip_file?
    zip_file_path.exist?
  end

  def tree_json
    if json_for_file_tree.blank?
      require 'togodb/zip_handler'

      zip_handler = Togodb::ZipHandler.new
      self.json_for_file_tree = zip_handler.to_json(zip_file_path, togodb_table.name)
      save
    end

    json_for_file_tree
  end

  def move_files(src_zip_file_path, src_extracted_dir_path)
    delete_supplementary_files
    FileUtils.mv(src_zip_file_path, zip_file_path)
    FileUtils.mv(src_extracted_dir_path, zip_extract_dir_path)
  end

  def file_path_by_url_path(url_path)
    zip_extract_dir_path.join(url_path)
  end

  private

  def uploaded_files_save_path
    path = Pathname.new(Togodb.supfile_dir)
    path.join(table.name)
  end

  def zip_file_path
    uploaded_files_save_path.join(original_filename)
  end

  def zip_extract_dir_path
    uploaded_files_save_path.join('files')
  end

  def delete_supplementary_files
    FileUtils.remove_file(zip_file_path) if zip_file_path.exist?
    FileUtils.rm_r(zip_extract_dir_path, secure: true) if zip_extract_dir_path.exist?
  end

  def create_base_dir
    FileUtils.mkdir_p(uploaded_files_save_path) unless uploaded_files_save_path.exist?
  end

  def delete_base_dir
    FileUtils.rm_r(uploaded_files_save_path, secure: true) if uploaded_files_save_path.exist?
  end

end

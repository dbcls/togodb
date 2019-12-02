module ReleasesHelper

  def show_db_release_column?(datasets)
    datasets.each do |ds|
      return true if ds.can_submit_job?
    end

    false
  end

  def data_download_url(table, dataset_name, format)
    #text = file_size(table_name, dataset_name, format)
    #if text.blank?
    #  text
    #else
      base_name = if table.dl_file_name.blank?
        table.name
      else
        table.dl_file_name
                  end
      id = if dataset_name == 'default'
        base_name
      else
        "#{base_name}-#{dataset_name}"
           end
      #link_to text, download_release_path(@table.name, format: format), class: "togodb-#{table_name}-released-data-dl-link"
      "/release/#{id}.#{format}"
    #end
  end

  def data_download_link0(table_name, dataset_name, format)
    text = file_size(table_name, dataset_name, format)
    if text.blank?
      text
    else
      id = if dataset_name == 'default'
        table_name
      else
        "#{table_name}-#{dataset_name}"
           end
      #link_to text, download_release_path(@table.name, format: format), class: "togodb-#{table_name}-released-data-dl-link"
      link_to text, "/release/#{id}.#{format}", class: "togodb-#{table_name}-released-data-dl-link"
    end
  end

  def file_size(table_name, dataset_name, format)
    table = TogodbTable.find_by(name: table_name)
    #if table.migrate_ver == 'semantic' || table.migrate_ver == 'v3'
    #  fpath = "/data/togodb/data-migration/release-data/#{table.migrate_ver}/#{table_name}_#{dataset_name}.#{format}"
    #else
      fpath = "#{Togodb.dataset_dir}/#{table_name}_#{dataset_name}.#{format}"
    #end

    if File.exists?(fpath)
      #number_with_delimiter File.size(fpath)
      number_to_human_size File.size(fpath)
    else
      ''
    end
  end

  def release_html(dataset)
    if dataset.can_submit_job?
      link_to "Release", release_togodb_dataset_path(dataset), remote: true
    else
      ''
    end
  end

  def relase_file_exist?(table_name, dataset_name, format)
    table = TogodbTable.find_by(name: table_name)
    #if table.migrate_ver == 'semantic' || table.migrate_ver == 'v3'
    #  fpath = "/data/togodb/data-migration/release-data/#{table.migrate_ver}/#{table_name}_#{dataset_name}.#{format}"
    #else
      fpath = "#{Togodb.dataset_dir}/#{table_name}_#{dataset_name}.#{format}"
    #end
    #fpath = "#{Togodb.dataset_dir}/#{table_name}_#{dataset_name}.#{format}"

    File.exist?(fpath)
  end

end

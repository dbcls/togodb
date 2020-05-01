class TogodbTable < ApplicationRecord
  has_many :togodb_columns, class_name: 'TogodbColumn', foreign_key: 'table_id', dependent: :delete_all
  has_many :togodb_datasets, class_name: 'TogodbDataset', foreign_key: 'table_id', dependent: :delete_all
  has_one :page, class_name: 'TogodbPage', foreign_key: 'table_id', dependent: :delete
  belongs_to :creator, class_name: 'TogodbUser', foreign_key: 'creator_id'
  has_many :roles, class_name: 'TogodbRole', foreign_key: 'table_id', dependent: :delete_all
  has_one :supplementary_files, class_name: 'TogodbSupplementaryFile', foreign_key: 'togodb_table_id', dependent: :destroy
  has_one :metadata, class_name: 'TogodbDbMetadata', foreign_key: 'table_id', dependent: :delete

  class << self

    def actual_primary_key(name)
      sql = "SELECT attr.attname FROM pg_constraint cons INNER JOIN pg_class cl ON cons.conrelid = cl.oid INNER JOIN pg_attribute attr ON attr.attrelid=cl.oid AND attr.attnum=cons.conkey[1] WHERE cons.contype='p' AND cl.relname='#{name}'"
      row = connection.query(sql)

      if row.empty?
        nil
      else
        row[0][0]
      end
    end

    def exist?(name)
      !where(name: name).or(where(page_name: name)).or(where(dl_file_name: name)).empty?
    end
  end


  def columns
    TogodbColumn.where(table_id: id).order(:position)
  end

  def csv_cols_for_data_import_job
    TogodbColumn.where(table_id: id).order(:id).map { |column|
      {
          id: column.id,
          enabled: column.enabled,
          name: column.name,
          internal_name: column.internal_name,
          data_type: column.data_type
      }
    }
  end

  def enabled_columns
    TogodbColumn.where(table_id: id).order(:id).select(&:enabled)
  end

  def list_columns
    TogodbColumn.where("table_id=? AND SUBSTR(actions,1,1)='1'", id).order('list_disp_order')
  end

  def view_show_merged_ordered_columns
    self.columns.select(&:action_list?)
  end

  def simple_search_columns
    enabled_columns.select(&:action_search)
  end

  def advanced_search_columns
    enabled_columns.select(&:action_luxury)
  end

  def default_sorting_column
    if sort_col_id
      TogodbColumn.find(sort_col_id)
    else
      nil
    end
  end

  def webservice_column?
    columns.each do |column|
      return true if column.web_service?
    end

    false
  end

  def id_separator_columns
    columns.select(&:has_id_separator?)
  end

  def class_name
    name.capitalize
  end

  def representative_name
    page_name.blank? ? name : page_name
  end

  def label
    representative_name.humanize
  end

  def pk_column
    if pkey_col_id
      TogodbColumn.find(pkey_col_id)
    else
      nil
    end
  end

  def pk_column_name
    column = pk_column
    if column
      column.name
    else
      'id'
    end
  end

  def pk_column_internal_name
    column = pk_column
    if column
      column.internal_name
    else
      'id'
    end
  end

  def primary_key_column_name
    pkey_column = primary_key_column
    if pkey_column
      pkey_column.name
    else
      'id'
    end
  end

  def primary_key_column
    if pkey_col_id
      TogodbColumn.find(pkey_col_id)
    else
      TogodbColumn.find_by(name: 'id', internal_name: 'id', table_id: id, enabled: true)
    end
  end

  ######################################################################
  ### Activator Methods

  def construct(activator = Togodb::Generator::Model)
    activator.new(self).construct
  end

  def destruct(activator = Togodb::Generator::Model)
    activator.new(self).destruct
  end

  def active_record
    model = Object.const_get class_name
  rescue NameError, LoadError
    Object.const_set class_name, Class.new(ApplicationRecord)
    model = Object.const_get class_name
  ensure
    model.table_name = name
    model.acts_as_copy_target

    model
  end

  def create_table
    ActiveRecord::Migration.create_table name.to_sym do |t|
      TogodbColumn.where(table_id: id).order(:id).each do |column|
        next unless column.enabled

        eval "t.#{column.data_type} :#{column.internal_name}"
      end
    end
  end

  def drop_table
    if ActiveRecord::Migration.data_source_exists?(name)
      ActiveRecord::Migration.drop_table name
    end
  end

  def column_values(column_name)
    rows = active_record.select("DISTINCT #{column_name}").order(column_name)
    rows.map { |r| r.send column_name }
  end

  def update_column_values_table(record)
    list_type_columns.each do |column|
      value = record[column.name]
      unless TogodbColumnValue.where(column_id: column_id, value: value).exists?
        c = TogodbColumnValue.new(column_id: column.id, value: value)
        c.save!
      end
    end
  end

  def refresh_column_values
    columns.select(&:list_type?).each do |column|
      TogodbColumnValue.delete_all(column_id: column.id)
      column_values(column.internal_name).each do |value|
        m = TogodbColumnValue.new(column_id: column.id, value: value)
        m.save!
      end
    end
  end

  def insert_column_values
    columns.select(&:list_type?).each do |column|
      column_values(column.internal_name).each do |value|
        m = TogodbColumnValue.new(column_id: column.id, value: value)
        m.save!
      end
    end
  end

  def delete_column_values
    columns.select(&:list_type?).each do |column|
      TogodbColumnValue.delete_all(column_id: column.id)
    end
  end

  def has_resource_class?
    !resource_class.to_s.strip.empty?
  end

  def has_resource_label?
    !resource_label.to_s.strip.empty?
  end

  def resource_label_default
    "#{name}:{#{pk_column_name}}"
  end

  def role_for(user = current_user)
    if user
      TogodbRole.where(table_id: id, user_id: user.id).first
    else
      nil
    end
  end

  def default_dataset
    TogodbDataset.find_by(name: 'default', table_id: self.id)
  end

  def valid_name?(name)
    valid_name = true
    TogodbTable.where(name: name).or(TogodbTable.where(page_name: name)).or(TogodbTable.where(dl_file_name: name)).each do |table|
      if table.id != self.id
        valid_name = false
        break
      end
    end

    valid_name
  end

  def delete_database
    release_file_paths = release_files

    ActiveRecord::Base.transaction do
      work = Work.find_by(name: name)
      work.destroy! if work

      drop_table
      destroy!

      release_file_paths.each do |file_path|
        File.delete(file_path) if File.exist?(file_path)
      end
    end
  end

  def release_files
    files = []
    togodb_datasets.each do |dataset|
      %w(csv json ttl rdf fasta).each do |file_format|
        files << Togodb::DataRelease.output_file_path(name, dataset.name, file_format)
      end
    end

    files
  end
end

module Togodb
  COLUMN_PREFIX = 'col_'.freeze

  class ExpectedError < RuntimeError; end
  class FileNotFound < StandardError; end

  mattr_accessor :app_server
  mattr_accessor :redis_host, :redis_port
  mattr_accessor :tmp_dir, :upfile_saved_dir, :dataset_dir, :supfile_dir
  mattr_accessor :data_download_queue, :data_import_queue, :db_copy_queue, :data_release_queue, :new_rdf_repository_queue
  mattr_accessor :create_release_files, :create_new_repository
  mattr_accessor :use_graphdb
  mattr_accessor :graphdb_server
  mattr_accessor :rapper_path, :nkf_path, :psql_path
  mattr_accessor :d2rq_base_uri
  mattr_accessor :enable_open_search, :open_search_admin_mail
  mattr_accessor :encrypt_password


  def self.valid_table_name?(name)
    /\A[a-z][a-z0-9_]*[a-z0-9]\z/ === name.to_s
  end

  def self.reserved_table_name?(name)
    name.to_s[0, 7] == 'togodb_' || self.reserved_table_name.include?(name.to_s)
  end

  def self.valid_column_name?(name)
    return false unless /(\A[a-z]\z)|(\A[a-z][a-z0-9_]*[a-z0-9]\z)/ === name.to_s
    self.not_reserved_column_name?(name)
  end

  def self.not_reserved_column_name?(name)
    #    return false if ActiveRecord::Base.method_defined?(name)
    #    return false if ActiveRecord::Base.private_method_defined?(name)
    #    return false if name == 'conditions'
    #    return false if name == 'target'
    #    return false if /^proxy_/ =~ name
    true
  end

  def self.reserved_table_name
    Togodb::Release::ACTIONS
  end

  def self.database_configuration
    require 'yaml'
    require 'erb'

    begin
      rails_env = Rails.env || 'production'
    rescue
      rails_env = 'production'
    end

    default_config = {
        adapter: 'postgresql',
        host: nil,
        port: 5432,
        database: "togodb_#{rails_env}",
        username: nil,
        password: nil
    }

    yaml = Rails.root.join('config', 'database.yml')
    db_config = YAML.load(ERB.new(yaml.read).result)
    if db_config
      {
          adapter: db_config[rails_env]['adapter'] || default_config[:adapter],
          host: db_config[rails_env]['host'] || default_config[:host],
          port: db_config[rails_env]['port'].to_i || default_config[:port],
          database: db_config[rails_env]['database'] || default_config[:database],
          username: db_config[rails_env]['username'] || default_config[:username],
          password: db_config[rails_env]['password'] || default_config[:password]
      }
    else
      default_config
    end
  end

end

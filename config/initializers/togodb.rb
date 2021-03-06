require 'fileutils'
require 'togodb'

Togodb.app_server = ENV.fetch("BASE_URI_HOST")

Togodb.redis_host = ENV.fetch("REDIS_HOST") { "127.0.0.1" }
Togodb.redis_port = ENV.fetch("REDIS_PORT") { 6379 }
Resque.redis = "#{Togodb.redis_host}:#{Togodb.redis_port}"

# Directories
data_dir = ENV.fetch("DATA_DIR")
Togodb.tmp_dir = ENV.fetch("TMP_DIR")
Togodb.upfile_saved_dir = "#{data_dir}/upload_files"
Togodb.dataset_dir = "#{data_dir}/release_files"
Togodb.supfile_dir = "#{data_dir}/supplementary_files"

FileUtils.mkdir_p(Togodb.upfile_saved_dir) unless File.exist?(Togodb.upfile_saved_dir)
FileUtils.mkdir_p(Togodb.dataset_dir) unless File.exist?(Togodb.dataset_dir)
FileUtils.mkdir_p(Togodb.supfile_dir) unless File.exist?(Togodb.supfile_dir)
FileUtils.mkdir_p(Togodb.tmp_dir) unless File.exist?(Togodb.tmp_dir)

# Program path
Togodb.rapper_path = ENV.fetch("RAPPER_PATH") { "rapper" }
Togodb.nkf_path = ENV.fetch("NKF_PATH") { "nkf" }
Togodb.psql_path = ENV.fetch("PSQL_PATH") { "psql" }

# D2RQ
Togodb.d2rq_base_uri = "http://#{Togodb.app_server}/"

# QUEUE names
Togodb.data_download_queue = Rails.configuration.x.togodb[:resque][:data_download_queue].to_sym
Togodb.data_import_queue = Rails.configuration.x.togodb[:resque][:data_import_queue].to_sym
Togodb.db_copy_queue = Rails.configuration.x.togodb[:resque][:db_copy_queue].to_sym
Togodb.data_release_queue = Rails.configuration.x.togodb[:resque][:data_release_queue].to_sym
Togodb.new_rdf_repository_queue = Rails.configuration.x.togodb[:resque][:new_rdf_repository_queue].to_sym
Togodb.create_release_files = Rails.configuration.x.togodb[:run_data_release_after_import]

# OpenSearch
Togodb.enable_open_search = Rails.configuration.x.togodb[:open_search][:enable]
Togodb.open_search_admin_mail = Rails.configuration.x.togodb[:open_search][:admin_email]

Togodb.create_new_repository = true
Togodb.use_graphdb = ENV.fetch("USE_GRAPHDB") { false }
if Togodb.use_graphdb.is_a?(String)
  if %(true t 1).include?(Togodb.use_graphdb.downcase)
    Togodb.use_graphdb = true
  else
    Togodb.use_graphdb = false
  end    
end

Togodb.graphdb_server = ENV.fetch("GRAPHDB_SERVER") { "http://localhost:7200/" }

Togodb.encrypt_password = true

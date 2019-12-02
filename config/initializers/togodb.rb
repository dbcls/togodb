require 'fileutils'
require 'togodb'

Togodb.app_server = ENV.fetch("BASE_URI_HOST")

# Get Redis host and port
if ENV['REDIS_URL']
  require 'uri'
  uri = URI.parse(ENV['REDIS_URL'])
  Togodb.redis_host = uri.host
  Togodb.redis_port = uri.port
else
  Togodb.redis_host = ENV.fetch("REDIS_HOST") { "127.0.0.1" }
  Togodb.redis_port = ENV.fetch("REDIS_PORT") { 6379 }
end

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

# D2RQ
Togodb.d2rq_base_uri = "http://#{Togodb.app_server}/"

# QUEUE names
Togodb.data_download_queue = Rails.configuration.x.togodb[:resque][:data_download_queue].to_sym
Togodb.data_import_queue = Rails.configuration.x.togodb[:resque][:data_import_queue].to_sym
Togodb.db_copy_queue = Rails.configuration.x.togodb[:resque][:db_copy_queue].to_sym
Togodb.data_release_queue = Rails.configuration.x.togodb[:resque][:data_release_queue].to_sym

Togodb.create_release_files = Rails.configuration.x.togodb[:run_data_release_after_import]

# OpenSearch
Togodb.enable_open_search = Rails.configuration.x.togodb[:open_search][:enable]
Togodb.open_search_admin_mail = Rails.configuration.x.togodb[:open_search][:admin_email]

Togodb.create_new_repository = false
Togodb.use_owlim = false

togodb_config = Rails.application.config_for(:togodb)

Rails.application.config.to_prepare do
  Togodb.app_server = ENV.fetch("BASE_URI_HOST")

  # Get Redis host and port
  # if ENV['REDIS_URL']
  #   require 'uri'
  #   uri = URI.parse(ENV['REDIS_URL'])
  #   Togodb.redis_host = uri.host
  #   Togodb.redis_port = uri.port
  # else
  Togodb.redis_host = ENV.fetch("REDIS_HOST") { "127.0.0.1" }
  Togodb.redis_port = ENV.fetch("REDIS_PORT") { 6379 }
  # end
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
  Togodb.data_download_queue = togodb_config[:resque][:data_download_queue].to_sym
  Togodb.data_import_queue = togodb_config[:resque][:data_import_queue].to_sym
  Togodb.db_copy_queue = togodb_config[:resque][:db_copy_queue].to_sym
  Togodb.data_release_queue = togodb_config[:resque][:data_release_queue].to_sym
  Togodb.new_rdf_repository_queue = togodb_config[:resque][:new_rdf_repository_queue].to_sym
  Togodb.create_release_files = togodb_config[:run_data_release_after_import]

  # OpenSearch
  Togodb.enable_open_search = togodb_config[:open_search][:enable]
  Togodb.open_search_admin_mail = togodb_config[:open_search][:admin_email]

  Togodb.create_new_repository = true
  Togodb.use_graphdb = %(true t 1).include?(ENV.fetch("USE_GRAPHDB").to_s.downcase)
  Togodb.graphdb_server = ENV.fetch("GRAPHDB_SERVER")

  if ENV.fetch("ENCRYPT_PASSWORD") { false }.to_s == 'true'
    Togodb.encrypt_password = true
  else
    Togodb.encrypt_password = false
  end
end

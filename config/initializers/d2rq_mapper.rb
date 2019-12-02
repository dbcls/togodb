SECURE = ENV.fetch("ENCRYPTOR_SECURE") { "" }
CIPHER = 'aes-256-cbc'
EXAMPLE_RECORDS_MAX_ROWS = 5
D2RQ_DUMPED_TURTLE_LINES = 100

Rails.application.config.to_prepare do
  TogoMapper.d2rq_path = ENV.fetch("D2RQ_DIR")
end

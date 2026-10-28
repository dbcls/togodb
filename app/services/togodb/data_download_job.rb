class Togodb::DataDownloadJob
  @queue = Togodb.data_download_queue

  class << self
    def perform(create_id, url, key)
      downloader = Togodb::DataDownloader.new(create_id, url, key)
      downloader.download
    end
  end

end

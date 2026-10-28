require 'uri'
require 'net/http'
require 'redis'
require 'csv'

class Togodb::DataDownloader
  include Togodb::DatabaseCreator
  include Togodb::FileUtils

  class << self
    def total_key(key)
      "data_download_#{key}_total"
    end

    def populated_key(key)
      "data_download_#{key}_populated"
    end

    def warning_msg_key(key)
      "data_download_#{key}_warning"
    end

    def error_msg_key(key)
      "data_download_#{key}_error"
    end
  end


  def initialize(create_id, url, key)
    @create = TogodbCreate.find(create_id)
    @url = url
    @key = key

    @file_format = @create.file_format
    @output_file = @create.uploded_file_path

    @redis = Redis.new(host: Togodb.redis_host, port: Togodb.redis_port)
  end

  def download
    url = URI.parse(@url)

    #request = Net::HTTP::Get.new(url.path)
    request = Net::HTTP::Get.new(url.request_uri)
    downloaded_size = 0
    done = 0

    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = http.get(url.request_uri)
    case response
    when Net::HTTPSuccess
      content_length = response['content-length']
      if content_length
        content_length = content_length.to_i
      else
        @redis.set warning_key, "Cannot get the data size."
      end
      @redis.set total_key, content_length
      File.open(@output_file, "wb") do |out|
         out.write response.body
      end
      #--> File.open(@output_file, "wb") do |out|
      #-->   response.read_body do |data|
      #-->     downloaded_size += data.size
      #-->     out.write data
      #-->     if content_length
      #-->       if downloaded_size == content_length
      #-->         progress = 100
      #-->       else
      #-->         progress = ((downloaded_size.to_f / content_length.to_f) * 100).to_i
      #-->       end
      #-->       if done < progress
      #-->         @redis.set populated_key, done.to_s
      #-->         done = progress
      #-->       end
      #-->     end
      #-->   end
      #--> end
    else
      puts response.message
      @redis.set error_key, "Server returns status #{response.code}: #{response.message}"
    end
=begin
    Net::HTTP.start(url.host, url.port) do |http|
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess
          content_length = response['content-length']
          if content_length
            content_length = content_length.to_i
          else
            @redis.set warning_key, "Cannot get the data size."
          end
          @redis.set total_key, content_length
          File.open(@output_file, "wb") do |out|
            response.read_body do |data|
              downloaded_size += data.size
              out.write data
              if content_length
                if downloaded_size == content_length
                  progress = 100
                else
                  progress = ((downloaded_size.to_f / content_length.to_f) * 100).to_i
                end
                if done < progress
                  @redis.set populated_key, done.to_s
                  done = progress
                end
              end
            end
          end
        else
          puts response.message
          @redis.set error_key, "Server returns status #{response.code}: #{response.message}"
        end
      end
    end
=end
    sleep(3)
    @redis.set populated_key, 100.to_s
    # convert_to_utf8(@output_file, utf8_file(@file_format))
    @create.input_file_encoding = detect_char_code(@output_file)
    @create.save!
    @redis.set populated_key, 200.to_s
  rescue => e
    puts e.message
    puts e.backtrace
    @redis.set error_key, e.message
  end

  private

  def check_data(file)
    3.times do
      CSV.foreach(file) do |row|
      end
      break
    rescue ArgumentError => e

    rescue CSV::MalformedCSVError => e
      @redis.set error_key, e.message
      break
    end
  end

  def total_key
    self.class.total_key(@key)
  end

  def populated_key
    self.class.populated_key(@key)
  end

  def warning_key
    self.class.warning_msg_key(@key)
  end

  def error_key
    self.class.error_msg_key(@key)
  end

end

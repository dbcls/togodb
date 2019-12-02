require 'fileutils'

namespace "togodb" do
  desc "Setup TogoDB application"
  task :setup => :environment do
    env_file = Rails.root.join('.env')
    File.open(env_file, 'a') do |f|
      f.puts
      f.puts "#===== Do not edit this line ====="
      f.puts "ENCRYPTOR_SECURE = #{SecureRandom::hex(16)}"
    end

    pid_dir = Rails.root.join('tmp', 'pids')
    FileUtils.mkdir_p(pid_dir) unless File.exist?(pid_dir)
  end
end

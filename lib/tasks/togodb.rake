require 'fileutils'

namespace "togodb" do
  desc 'Create admin account'
  task :create_admin_account => :environment do
    TogodbUser.regist(ENV['TOGODB_ADMIN_USER'], ENV['TOGODB_ADMIN_PASSWORD'], true)
  end

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

  desc "Delete guest user's database"
  task :destroy_guest_user_databases => :environment do
    guest_user = TogodbUser.find_by(login: 'guest')
    return if guest_user.nil?

    TogodbTable.where('creator_id = ? AND created_at < ?', guest_user.id, 12.hours.ago).each do |table|
      table.delete_database
      puts "#{Time.now} '#{table.name}' is deleted."
    end
  end
end

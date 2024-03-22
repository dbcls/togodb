require 'yaml'

class File
  class << self
    def exists?(path)
      exist?(path)
    end
  end
end

module God
  module System
    class SlashProcPoller
      def self.readable?(path)
        begin
          Timeout::timeout(1) { File.read(path) }
        rescue Timeout::Error
          false
        end
      end
    end
  end
end

rails_env = ENV['RAILS_ENV'] || 'development'
rails_root = ENV['RAILS_ROOT'] || File.expand_path(File.join(__dir__, '..'))
rake = 'bin/rails'
God.pid_file_directory = "#{rails_root}/tmp/pids"

# jobs = [
#   { queue: 'togodb_data_download',     num_workers: 1 },
#   { queue: 'togodb_data_import',       num_workers: 5 },
#   { queue: 'togodb_db_copy',           num_workers: 5 },
#   { queue: 'togodb_data_release',      num_workers: 2 },
#   { queue: 'togodb_db_rdf_repository', num_workers: 1 }
# ]
togodb_config = YAML.load_file("#{rails_root}/config/togodb.yml", aliases: true)
jobs = []
togodb_config[rails_env]['resque'].each_value do |queue|
  jobs << { queue: queue['name'], num_workers: queue['num_workers'] }
end

jobs.each do |job|
  queue_name = job[:queue]
  job[:num_workers].times do |num|
    God.watch do |w|
      w.dir      = rails_root
      w.name     = "resque-#{queue_name}-#{num + 1}"
      w.group    = "resque-#{queue_name}"
      w.log      = "#{rails_root}/log/#{queue_name}-#{num + 1}.log"
      w.interval = 30.seconds

      w.env      = { 'QUEUE' => queue_name, 'RAILS_ENV' => rails_env }
      w.start    = "#{rake} -f Rakefile environment resque:work"

      # clean pid files before start if necessary
      w.behavior(:clean_pid_file)

      # determine the state on startup
      w.transition(:init, { true => :up, false => :start }) do |on|
        on.condition(:process_running) do |c|
          c.running = true
        end
      end

      # determine when process has finished starting
      w.transition([:start, :restart], :up) do |on|
        on.condition(:process_running) do |c|
          c.running = true
        end

        # failsafe
        on.condition(:tries) do |c|
          c.times = 5
          c.transition = :start
        end
      end

      # start if process is not running
      # ERROR: Condition 'God::Conditions::ProcessExits' requires an event system but none has been loaded
      #--> w.transition(:up, :start) do |on|
      #-->   on.condition(:process_exits)
      #--> end

      # restart if memory or cpu is too high
      w.transition(:up, :restart) do |on|
        on.condition(:memory_usage) do |c|
          c.interval = 20
          c.above = 1024.megabytes
          c.times = [3, 5]
        end

        on.condition(:cpu_usage) do |c|
          c.interval = 10
          c.above = 50.percent
          c.times = [3, 5]
        end
      end

      # lifecycle
      w.lifecycle do |on|
        on.condition(:flapping) do |c|
          c.to_state = [:start, :restart]
          c.times = 5
          c.within = 5.minute
          c.transition = :unmonitored
          c.retry_in = 10.minutes
          c.retry_times = 5
          c.retry_within = 2.hours
        end
      end
    end
  end
end

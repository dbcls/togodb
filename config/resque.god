#-----------------------------------------------------------------------
#rails_root  = ENV['RAILS_ROOT'] || "/data/togodb/togodb3/rails3/togodb"
#rake = "/data/togodb/togodb3/local/bin/rake"
rails_root  = ENV['RAILS_ROOT'] || "/data/togodb/v4/rails/production/current"
#rake = "bundle exec rake"
#-----------------------------------------------------------------------

jobs = [
  { :queue => "togodb_v4_dl", :num_workers => 4 },
  { :queue => "togodb_v4_di", :num_workers => 4 },
  { :queue => "togodb_v4_cp", :num_workers => 4 },
  { :queue => "togodb_v4_re", :num_workers => 4 },
  { :queue => "togodb_v4_nr", :num_workers => 4 },
]

rails_env = ENV['RAILS_ENV']  || "production"

God.pid_file_directory = "#{rails_root}/tmp/pids"

jobs.each do |job|
  job[:num_workers].times do |num|
    God.watch do |w|
      w.dir      = "#{rails_root}"
      w.name     = "resque-#{job[:queue]}-#{num}"
      w.group    = "resque-#{job[:queue]}"
      w.interval = 30.seconds
      w.env      = {"QUEUE" => "#{job[:queue]}", "RAILS_ENV" => rails_env}
      #w.start    = "#{rake} -f #{rails_root}/Rakefile environment resque:work"
      w.start    = "rake environment resque:work"

      w.behavior(:clean_pid_file)

      # restart if memory gets too high
      w.transition(:up, :restart) do |on|
	on.condition(:memory_usage) do |c|
	  c.above = 350.megabytes
	  c.times = 2
	end
      end

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
	  c.interval = 5.seconds
	end

        # failsafe
	on.condition(:tries) do |c|
	  c.times = 5
	  c.transition = :start
	  c.interval = 5.seconds
	end
      end

      # start if process is not running
      w.transition(:up, :start) do |on|
	on.condition(:process_running) do |c|
	  c.running = false
	end
      end
    end
  end
end

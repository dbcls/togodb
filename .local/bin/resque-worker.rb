#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path('../../../config/application', __FILE__)
Rails.application.require_environment!

class ResqueWorkerDaemon < DaemonSpawn::Base
  def start(args)
    @worker = Resque::Worker.new('togodb_v4_dl', 'togodb_v4_di', 'togodb_v4_cp', 'togodb_v4_re')
    @worker.verbose = true
    @worker.work
  end

  def stop
    @worker.try(:shutdown)
  end
end

ResqueWorkerDaemon.spawn!(
  {
    processes:   2,
    working_dir: Rails.root,
    pid_file:    File.join(Rails.root, 'tmp', 'pids', 'resque_worker.pid'),
    log_file:    File.join(Rails.root, 'log', 'resque_worker.log'),
    sync_log:    true,
    singleton:   true,
    signal:      'QUIT'
  }
)

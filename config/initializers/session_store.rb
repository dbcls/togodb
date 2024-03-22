# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_togodb_session'
=begin
redis_host = ENV.fetch("REDIS_HOST") { "127.0.0.1 " }
redis_port = ENV.fetch("REDIS_PORT") { 6379 }
Rails.application.config.session_store :redis_store,
                                       servers: ["redis://#{redis_host}:#{redis_port}/0/session"],
                                       key: '_togodb_v4_session',
                                       threadsafe: true,
                                       expire_after: 120.minutes
=end

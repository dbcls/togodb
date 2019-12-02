# Be sure to restart your server when you modify this file.

#-->Rails.application.config.session_store :cookie_store, key: '_togodb_session'
Rails.application.config.session_store :redis_store, {
  servers: {
    host: ENV.fetch("REDIS_HOST") { "127.0.0.1 "},
    port: ENV.fetch("REDIS_PORT") { 6379 },
    db: 0,
    namespace: '_togodb_v4_session'
  },
  expire_after: 120.minutes
}

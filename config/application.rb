require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Togodb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.eager_load_paths += Dir["#{Rails.root}/lib"]
    config.generators.template_engine = :slim

    # I18n
    config.i18n.fallbacks = true
    config.i18n.available_locales = [:en]
    config.i18n.default_locale = :en

    # TogoDB configuration
    config.x.togodb = ActiveSupport::InheritableOptions.new config_for(:togodb).deep_symbolize_keys
  end
end

source 'https://rubygems.org'

ruby '3.3.0'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.3'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '>= 4.0.1'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Sass to process CSS
gem 'sassc-rails'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

# capistrano
group :development do
  #gem "capistrano", "~> 3.11", require: false
  #gem "capistrano-git-copy", require: false
  #gem 'capistrano-bundler', '~> 1.6', require: false
  #gem 'capistrano-rails', '~> 1.4', require: false
  #gem 'capistrano-rbenv', '~> 2.1', require: false
  #gem 'sshkit-sudo', require: false
  #gem 'capistrano3-puma', require: false
  gem 'capistrano', require: false
  gem 'capistrano3-puma', github: "seuros/capistrano-puma"
  gem 'capistrano-bundler', require: false
  gem 'capistrano-git-copy', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rbenv', require: false
  gem 'sshkit-sudo', require: false
end

# gems for TogoDB
gem 'browser'
gem 'coffee-rails'
# gem 'daemon-spawn', require: 'daemon_spawn'
gem 'dotenv-rails'
gem 'dsl_accessor'
gem 'flavour_saver'
gem 'god'
gem 'jquery-rails'
# gem 'json'
gem 'mini_racer'
gem 'nokogiri'
# gem 'open_id_authentication'
gem 'postgres-copy'
gem 'rack-cors'
gem 'rdf'
gem 'rdf-rdfxml'
gem 'rdf-turtle', '3.2.0'
gem 'redis-rails'
gem 'resque'
gem 'rubyzip', '~> 2.3'
gem 'slim-rails'
gem 'uuid'
# gem 'yajl-ruby'

# devise and omniauth
gem 'devise'
gem 'omniauth'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'

gem 'puma-daemon', require: false
gem 'rubocop', require: false

# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'

# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails'
gem 'terser'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use ActiveStorage variant
gem 'matrix'
gem 'net-ldap'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem "honeybadger", "~> 4.0"

group :development, :test do
  gem 'bixby'
  gem 'brakeman'
  gem 'dotenv-rails'
  gem "factory_bot_rails"
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rubocop', "~> 1.22"
  gem 'rubocop-rails'
  gem 'solargraph'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'capistrano', '>= 3.14.1'
  gem 'capistrano-passenger'
  gem 'capistrano-rails', '~> 1.1.6'
  gem 'database_cleaner-active_record'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rspec-rails'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'axe-core-api'
  gem 'axe-core-rspec'
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem "simplecov", require: false
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem "timecop"
  gem "webdrivers"
  gem "webmock"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'cancancan'
gem "devise", ">= 4.6.0"
gem 'foreman'
gem 'jwt'
gem 'multipart-post'
gem 'net-sftp'
gem 'nokogiri', "~> 1.14"
gem "omniauth", "~> 1.9"
gem 'omniauth-cas'
gem 'pg'
gem 'rubyzip'
gem 'whenever'

gem 'icalendar', '~> 2.8'

gem "vite_rails", "~> 3.0"

gem "capistrano-yarn", "~> 2.0"

gem 'archivesspace-client'
gem "flipflop", "~> 2.7"

gem "bcrypt_pbkdf", "~> 1.1"
gem "ed25519", "~> 1.3"

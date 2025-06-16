# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.2.2'

gem 'archivesspace-client'
gem 'aws-sdk-s3'
gem 'bcrypt_pbkdf', '~> 1.1'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
gem 'cancancan'
gem 'devise', '>= 4.6.0'
gem 'ed25519', '~> 1.3'
gem 'faraday', '~> 2.7'
gem "flipflop", git: "https://github.com/voormedia/flipflop.git", ref: "0d70d8e33483a9c0282ed8d6bca9c5ccd61e61e8"
gem 'foreman'
gem 'git'
gem "health-monitor-rails", "12.4.0"
gem 'honeybadger'
gem 'icalendar'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jwt'
gem 'library_stdnums'
gem 'marc'
gem 'marc_cleanup', github: "pulibrary/marc_cleanup", tag: 'v0.9.3', require: false
# Use ActiveStorage variant
gem 'matrix'
gem 'multipart-post'
gem 'net-ldap'
gem 'net-sftp'
gem 'nokogiri', '~> 1.18'
gem 'omniauth'
gem 'omniauth-cas'
gem 'omniauth-rails_csrf_protection'
gem 'open3'
gem 'pg'
# Use Puma as the app server
gem 'puma'
gem 'rubyzip'
# Use SCSS for stylesheets
gem 'sass-rails'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'whenever'

group :development, :test do
  gem 'bixby'
  gem 'brakeman'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec'
  gem 'rubocop', '~> 1.22'
  gem 'rubocop-rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'database_cleaner-active_record'
  gem 'rspec-rails'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'axe-core-api'
  gem 'axe-core-rspec'
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock'
end

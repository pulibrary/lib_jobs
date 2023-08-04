# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'

gem 'archivesspace-client'
gem 'bcrypt_pbkdf', '~> 1.1'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
gem 'cancancan'
# Should this be in the development block with the other capistrano dependencies?
gem 'capistrano-yarn', '~> 2.0'
gem 'devise', '>= 4.6.0'
gem 'ed25519', '~> 1.3'
gem "flipflop", git: "https://github.com/voormedia/flipflop.git", ref: "0d70d8e33483a9c0282ed8d6bca9c5ccd61e61e8"
gem 'foreman'
gem 'honeybadger', '~> 4.0'
gem 'icalendar', '~> 2.8'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jwt'
gem 'library_stdnums'
gem 'marc'
# Use ActiveStorage variant
gem 'matrix'
gem 'multipart-post'
gem 'net-ldap'
gem 'net-sftp'
gem 'nokogiri', '~> 1.14'
gem 'omniauth', '~> 1.9'
gem 'omniauth-cas'
gem 'open3'
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 4.3'
gem 'rubyzip'
# Use SCSS for stylesheets
gem 'sass-rails'
gem 'terser'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'vite_rails', '~> 3.0'
gem 'whenever'

group :development, :test do
  gem 'bixby'
  gem 'brakeman'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rubocop', '~> 1.22'
  gem 'rubocop-rails'
  gem 'solargraph'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'capistrano', '>= 3.14.1'
  gem 'capistrano-passenger'
  gem 'capistrano-rails', '~> 1.1.6'
  gem 'database_cleaner-active_record'
  gem 'listen', '>= 3.0.5'
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
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'webdrivers'
  gem 'webmock'
end

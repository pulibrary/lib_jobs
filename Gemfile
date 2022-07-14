# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'

# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.7'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

gem 'net-ldap'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem "honeybadger", "~> 4.0"
gem 'tiny_tds'

group :development, :test do
  gem 'bixby'
  gem 'dotenv-rails'
  gem "factory_bot_rails"
  gem 'pry-byebug'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'solargraph'
  gem 'sqlite3'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'capistrano', '>= 3.14.1'
  gem 'capistrano-passenger'
  gem 'capistrano-rails', '~> 1.1.6'
  gem 'database_cleaner-active_record'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rspec-rails'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
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
gem 'nokogiri', "~> 1.13"
gem "omniauth", "~> 1.9"
gem 'omniauth-cas'
gem 'pg'
gem 'rubyzip'
gem 'sidekiq', "~> 6.5"
gem 'webpacker'
gem 'whenever'

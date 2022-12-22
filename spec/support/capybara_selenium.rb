# frozen_string_literal: true
require "capybara/rspec"
require "selenium-webdriver"

default_directory = Rails.root.join('tmp', 'downloads')

# there's a bug in capybara-screenshot that requires us to name
#   the driver ":selenium" so we changed it from :headless_chrome"
Capybara.register_driver(:selenium_chrome) do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--disable-gpu"
  browser_options.args << "--disable-setuid-sandbox"
  browser_options.args << "--window-size=7680,4320"
  browser_options.add_preference(:download,
                                 prompt_for_download: false,
                                 default_directory:)
  browser_options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 120
  http_client.open_timeout = 120
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client:,
                                 options: browser_options)
end

Capybara.javascript_driver = :selenium_chrome
Capybara.default_max_wait_time = 15

Capybara.register_driver(:selenium_chrome_headless) do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless"
  browser_options.args << "--disable-gpu"
  browser_options.args << "--disable-setuid-sandbox"
  browser_options.args << "--window-size=7680,4320"
  browser_options.add_preference(:download,
                                 prompt_for_download: false,
                                 default_directory:)
  browser_options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 120
  http_client.open_timeout = 120
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client:,
                                 options: browser_options)
end

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 15

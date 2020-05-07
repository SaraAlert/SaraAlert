# frozen_string_literal: true

require 'system_test_case'

class MobileApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = ENV['APP_IN_CI'] ? :gitlab_chrome_headless : :chrome

  download_path = 'tmp/downloads'
  FileUtils.rm_rf(download_path) if File.exist?(download_path)

  Capybara.register_driver(driver) do |app|
    options = ::Selenium::WebDriver::Chrome::Options.new

    if ENV['APP_IN_CI']
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
    end

    options.add_preference('download.default_directory', download_path)

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  driven_by driver, using: :chrome, screen_size: [375, 667]
end

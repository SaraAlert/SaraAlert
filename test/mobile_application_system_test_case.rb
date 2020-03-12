# frozen_string_literal: true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV['APP_IN_CI']
    Capybara.register_driver(:gitlab_chrome_headless) do |app|
      options = ::Selenium::WebDriver::Chrome::Options.new

      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    driven_by :gitlab_chrome_headless, screen_size: [1400, 1400]
  else
    driven_by :selenium, using: :chrome, screen_size: [375, 667]
  end
end

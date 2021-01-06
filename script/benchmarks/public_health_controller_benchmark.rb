# frozen_string_literal: true

require_relative '../../config/environment'
require 'benchmark/ips'
require 'webdrivers/chromedriver'
require 'capybara/dsl'
include Capybara::DSL

# driver = ENV['APP_IN_CI'] ? :gitlab_chrome_headless : :chrome

# download_path = Rails.root.join('tmp/downloads')
# FileUtils.rm_rf(download_path) if File.exist?(download_path)

# Capybara.register_driver(driver) do |app|
#   options = ::Selenium::WebDriver::Chrome::Options.new

#   if ENV['APP_IN_CI']
#     options.add_argument('--headless')
#     options.add_argument('--no-sandbox')
#     options.add_argument('--disable-dev-shm-usage')
#   end

#   options.add_preference('download.default_directory', download_path)
#   options.add_argument('window-size=1920,1080')

#   Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
# end

# begin
#   driven_by driver, using: :chrome
# rescue Webdrivers::BrowserNotFound
#   driven_by :selenium, using: :firefox
# end

# Capybara.register_driver(:chrome) do |app|
#   Capybara::Selenium::Driver.new(app, browser: :remote, url: "http://0.0.0.0:3000/", desired_capabilities: :chrome)
# end

driver = ENV['APP_IN_CI'] ? :gitlab_chrome_headless : :selenium_chrome
Capybara.current_driver = :selenium_chrome
Capybara.app_host = 'http://0.0.0.0:3000/'
Capybara.run_server = false

def find_or_create_user(email, role, jurisdiction)
  User.find_or_create_by(email: email) do |user|
    user.password = '1234567ab!'
    user.role = role
    user.jurisdiction = jurisdiction
    user.force_password_change = false
    user.authy_enabled = false
    user.authy_enforced = false
    user.api_enabled = true
  end
end

usa = Jurisdiction.where(name: 'USA').first
ph_benchmark_user = find_or_create_user('ph_benchmark_user@example.com', Roles::PUBLIC_HEALTH, usa)
ct_benchmark_user = find_or_create_user('ct_benchmark_user@example.com', Roles::CONTACT_TRACER, usa)
phe_benchmark_user = find_or_create_user('phe_benchmark_user@example.com', Roles::PUBLIC_HEALTH_ENROLLER, usa)
su_benchmark_user = find_or_create_user('su_benchmark_user@example.com', Roles::SUPER_USER, usa)

# ct_benchmark_user = User.create(email: 'ct_benchmark_user@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)
# phe_benchmark_user = User.create(email: 'phe_benchmark_user@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)
# su_benchmark_user = User.create(email: 'su_benchmark_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)

def sign_in(user)
  visit "/users/sign_in"
  sleep 1
  sign_out unless page.current_path.include?("/users/sign_in")
  fill_in 'user_email', with: user.email
  fill_in 'user_password', with: '1234567ab!'
  click_on 'login'
end

def sign_out
  click_on 'Logout'
end


def wait_for_spinner_to_disappear(max_tries=60, wait_time=0.5)
  max_tries.times do
    break unless has_css?('.spinner-border')
    sleep wait_time
  end
end

def wait_for_public_health_dashboard(max_tries=60, wait_time=0.5)
  max_tries.times do
    break if page.current_path.include?("/public_health")
    sleep wait_time
  end
end 

# def wait_on_condition(&block, max_tries=60, wait_time=0.5)
#   max_tries.times do
#     break if block
#     sleep wait_time
#   end
# end

Benchmark.ips do |x|
  x.time = 30
  x.config(:iterations => 1)
  
  x.report("PUBLIC_HEALTH") { 
    sign_in(ph_benchmark_user)
    visit("/") 
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
    # byebug
  }

  x.report("CONTACT_TRACER") { 
    sign_in(ct_benchmark_user)
    visit("/") 
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  }

  x.report("PUB_HEALTH_ENROLLER") { 
    sign_in(phe_benchmark_user)
    visit("/") 
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  }

  x.report("SUPER_USER") { 
    sign_in(su_benchmark_user)
    visit("/") 
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  }

  x.compare!
end
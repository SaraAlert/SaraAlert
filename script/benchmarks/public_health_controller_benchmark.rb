# frozen_string_literal: true

# https://ruby-doc.org/stdlib-2.5.0/libdoc/benchmark/rdoc/Benchmark.html
# https://github.com/evanphx/benchmark-ips
# https://github.com/teamcapybara/capybara

require_relative '../../config/environment'
require 'benchmark/ips'
require 'webdrivers/chromedriver'
require 'capybara/dsl'
include Capybara::DSL # rubocop:disable Style/MixinUsage

driver = ENV['APP_IN_CI'] ? :gitlab_chrome_headless : :selenium_chrome
Capybara.current_driver = driver
Capybara.app_host = ENV['APP_HOST'] || 'http://0.0.0.0:3000/'
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

def sign_in(user)
  visit '/users/sign_in'
  sleep 1
  sign_out unless page.current_path.include?('/users/sign_in')
  fill_in 'user_email', with: user.email
  fill_in 'user_password', with: '1234567ab!'
  click_on 'login'
end

def sign_out
  click_on 'Logout'
end

def wait_for_spinner_to_disappear(max_tries = 60, wait_time = 0.5)
  max_tries.times do
    break unless has_css?('.spinner-border')

    sleep wait_time
  end
end

def wait_for_public_health_dashboard(max_tries = 60, wait_time = 0.5)
  max_tries.times do
    break if page.current_path.include?('/public_health')

    sleep wait_time
  end
end

timestamp = Time.now.utc.iso8601
benchmark_file = "script/benchmarks/output/public_health_controller_benchmark_#{timestamp}_BCM.log"
$stdout = File.new(benchmark_file, 'w')
$stdout.sync = true

Benchmark.bm(20) do |x|
  sign_in(ph_benchmark_user)
  visit('/')
  x.report('PUBLIC_HEALTH') do
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  end

  sign_in(ct_benchmark_user)
  visit('/')
  x.report('CONTACT_TRACER') do
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  end

  sign_in(phe_benchmark_user)
  visit('/')
  x.report('PUB_HEALTH_ENROLLER') do
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  end

  sign_in(su_benchmark_user)
  visit('/')
  x.report('SUPER_USER') do
    wait_for_public_health_dashboard
    wait_for_spinner_to_disappear
  end
end

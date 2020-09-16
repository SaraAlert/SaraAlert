# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.2', '>= 6.0.2.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sassc', '~> 2.3.0'
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Twillio gem for sending SMS and robo calls
gem 'twilio-ruby'
# Sidekiq for queueing
gem 'sidekiq'
# Ancestry for managing trees
gem 'ancestry'

# Devise, rolify for auth, doorkeeper for API
gem 'devise'
gem 'devise-authy'
gem 'devise-security'
gem 'doorkeeper'
gem 'rolify'

# Better React integration
gem 'react-rails'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Allow generation of synthetic data for demonstration purposes
gem 'faker'

# Gem for scheduling ActiveJobs to run
gem 'whenever', require: false

# Time parser for managing scheduled jobs
gem 'chronic'

# Store sessions in DB
gem 'activerecord-session_store'

# Useful db query helpers
gem 'activerecord_where_assoc'

# Pagination
gem 'will_paginate'

# Excel Import
gem 'roo'

# Excel Export
gem 'caxlsx'

# Used for inline css before mailer
gem 'premailer-rails'

# Split arch schema
gem 'sara-schema'

# Send errors to Sentry
gem 'sentry-raven'

# New Relic APM
gem 'newrelic_rpm'

# Better phone number handling
gem 'phonelib'

# Email address validation
gem 'valid_email2'

# Bulk db inserts
gem 'activerecord-import'

# ERB local time
gem 'local_time'

# FHIR models
gem 'fhir_models'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'gemsurance'
  gem 'rubocop'
end

group :development do
  gem 'bullet'
  gem 'letter_opener'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'minitest-retry'
  gem 'mocha'
  gem 'rack-test'
  gem 'rspec-mocks'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'simplecov-lcov'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.2', '>= 6.0.2.1'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
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

# Devise, and rolify for auth
gem 'devise'
gem 'devise-security'
gem 'rolify'

# Better React integration
gem 'react-rails'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Allow generation of synthetic data for demonstration purposes
gem 'faker'

# Gem for scheduling ActiveJobs to run
gem 'whenever', require: false

# Store sessions in DB
gem 'activerecord-session_store'

# Useful association queries
gem 'activerecord_where_assoc'

# Pagination
gem 'will_paginate'

# Excel
gem 'roo'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'gemsurance'
  gem 'rubocop'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'codecov'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

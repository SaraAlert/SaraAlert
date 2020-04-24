# frozen_string_literal: true

require 'simplecov'

SimpleCov.profiles.define 'saraalert' do
  load_profile 'rails'
  add_filter 'lib'
  if ENV['APP_IN_CI']
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end

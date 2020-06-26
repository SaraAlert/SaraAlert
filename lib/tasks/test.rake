# frozen_string_literal: true

namespace :test do
  desc 'Run system tests in parallel'
  task system_parallel: :environment do
    raise 'This task is only for use in a development/test environment' unless Rails.env == 'development' || Rails.env == 'test'

    puts 'whatever'
  end
end

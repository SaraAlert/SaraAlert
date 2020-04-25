# frozen_string_literal: true

namespace :coverage do
  task :report do
    require 'simplecov'
    require 'simplecov-lcov'
    SimpleCov.collate(Dir['coverage/.resultset.json'], 'rails') do
      # Generate a GitHub Actions compatible report
      SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
      formatter SimpleCov::Formatter::MultiFormatter.new([
        SimpleCov::Formatter::LcovFormatter,
        SimpleCov::Formatter::HTMLFormatter
      ])
    end
  end
end

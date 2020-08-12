# frozen_string_literal: true

require 'pathname'
require 'json'

def resource_paths(resource_types)
  Pathname.new(Rails.root.join('app', resource_types)).children.sort
end

def test_resource_paths(resource_types, resource)
  Rails.root.join('test', resource_types, "#{resource}_test.rb")
end

def run_test(test_path)
  if File.exist?(test_path)
    system("#{Rails.root.join('bin', 'rake')} test TEST=#{test_path} > /dev/null 2>&1")
    true
  else
    false
  end
end

def calculate_coverage(resource_path)
  coverage_file_path = Rails.root.join('coverage', '.resultset.json')
  exit(1, 'coverage/.ruleset.json does not exist') unless File.exist?(coverage_file_path)

  last_run = JSON.parse(File.read(coverage_file_path))

  # Refresh the coverage file each run
  File.delete(coverage_file_path)

  num_lines = last_run['TestCase']['coverage'][resource_path.to_s]['lines'].size
  uncovered = num_lines - last_run['TestCase']['coverage'][resource_path.to_s]['lines'].count(0)
  ((uncovered / num_lines.to_f) * 100).round(2)
end

def coverage(resource)
  resource_paths = resource_paths(resource)
  resources = resource_paths.map { |path| path.basename('.rb') }
  resources.zip(resource_paths).each do |resource_name, resource_path|
    test_path = test_resource_paths(resource, resource_name)
    if run_test(test_path)
      percent = calculate_coverage(resource_path)
      puts "#{resource_name} has #{percent}\% coverage"
    else
      puts "#{resource_name} has no associated test file at #{test_path}"
    end
  end
end

namespace :coverage do
  desc 'Generate a GitHub Actions compatible report'
  task :report do
    raise 'This task is only for use in a CI/CD testing environment' unless ENV['APP_IN_CI']

    require 'simplecov'
    require 'simplecov-lcov'

    # Expect a folder full of artifacts downloaded from GitHub actions within the
    # 'github-artifacts' folder. This filename is set in within the action itself
    SimpleCov.collate(Dir.glob('github-artifacts/coverage-*/**', File::FNM_DOTMATCH).reject { |file| file.end_with?('.') }, 'rails') do
      SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
      formatter SimpleCov::Formatter::MultiFormatter.new([
                                                           SimpleCov::Formatter::LcovFormatter,
                                                           SimpleCov::Formatter::HTMLFormatter
                                                         ])
    end
  end

  desc 'List test coverage for all models by running only that model\'s unit tests'
  task models: :environment do
    coverage('models')
  end

  desc 'List test coverage for all controllers by running only that controller\'s integration tests'
  task controllers: :environment do
    coverage('controllers')
  end
end

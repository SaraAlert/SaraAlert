require 'pathname'
require 'json'

namespace :test do
  desc 'List test coverage for all models by running only that model\'s unit tests'
  task model_coverage: :environment do
    model_paths = Pathname.new(Rails.root.join('app', 'models')).children.sort
    models = model_paths.map { |path| path.basename('.rb') }
    models.zip(model_paths).each do |model, path|
      test_path = Rails.root.join('test', 'models', "#{model}_test.rb")
      system("#{Rails.root.join('bin', 'rake')} test TEST=#{test_path} > /dev/null 2>&1")
      last_run = JSON.parse(File.read(Rails.root.join('coverage', '.resultset.json')))
      num_lines = last_run['TestCase']['coverage'][path.to_s]['lines'].size
      uncovered = num_lines - last_run['TestCase']['coverage'][path.to_s]['lines'].count(0)
      percent = ((uncovered.to_f / num_lines.to_f) * 100).round(2)
      puts "#{model} has #{percent}\% coverage"
    end
  end
end

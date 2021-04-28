# frozen_string_literal: true

require 'test_helper'
require 'migration_test_helper'

class MigrationTestCase < Minitest::Test
  include FactoryBot::Syntax::Methods

  def setup
    migration_class_name = self.class.name[0..-5]
    @migration = migration_class_name.constantize.new
    @migration_file = migration_path_name(migration_class_name.underscore)
    @current_schema_version = ActiveRecord::Migrator.current_version
  end

  def teardown
    run_migration(@current_schema_version, :up)
  end
end

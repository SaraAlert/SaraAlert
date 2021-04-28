# frozen_string_literal: true

def require_migration!(name = nil)
  if name.nil?
    call_location = caller_locations.detect { |location| /<class:.*Test>'$/.match?(location.to_s) }.label
    # ClassNameTest => class_name
    migration_name = call_location.scan(/^<class:(.*)Test/).flatten.first.underscore
    name = migration_path_name(migration_name)
    raise "Cannot find migration in #{ActiveRecord::Migrator.migrations_paths.first}" if name.nil?
  end

  require name
end

def migration_path_name(migration_name)
  Dir.glob(Rails.root.join(ActiveRecord::Migrator.migrations_paths.first, "*#{migration_name}.rb")).first
end

def migrated?(version)
  return true if ActiveRecord::Migrator.current_version >= version

  false
end

def rollback_to_previous_of!(migration_file)
  all_migrations = Dir.glob(Rails.root.join(ActiveRecord::Migrator.migrations_paths.first, '*.rb')).map { |file| Pathname.new(file).basename.to_s }.sort
  migration_file_basename = Pathname.new(migration_file).basename.to_s
  version_to_test = migration_file_basename.scan(/^\d*/).flatten.first
  previous_version_index = all_migrations.bsearch_index { |file| file >= migration_file_basename }
  previous_version_file_name = if previous_version_index == all_migrations.length - 1
                                 all_migrations[all_migrations.length - 2]
                               else
                                 all_migrations[previous_version_index - 1]
                               end
  previous_version = previous_version_file_name.scan(/^\d*/).flatten.first
  run_migration(previous_version.to_i, :down) if migrated?(version_to_test.to_i)
end

def upgrade_to!(migration_file)
  migration_file_basename = Pathname.new(migration_file).basename.to_s
  version = migration_file_basename.scan(/^\d*/).flatten.first
  run_migration(version.to_i, :up)
end

def run_migration(version, direction)
  migrations = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths, ActiveRecord::SchemaMigration).migrations
  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Migrator.new(direction, migrations, ActiveRecord::Base.connection.schema_migration, version).migrate
  end
end

class AddThresholdHashToJurisdictions < ActiveRecord::Migration[6.1]
  def up
    add_column :jurisdictions, :current_threshold_condition_hash, :string

    # Run admin:import_or_update_jurisdictions task without checks to ensure that threshold condition with :current_threshold_condition_hash exists
    ActiveRecord::Base.transaction do
      config_contents = YAML.load_file('config/sara/jurisdictions.yml')

      config_contents.each do |jur_name, jur_values|
        parse_jurisdiction(nil, jur_name, jur_values)
      end

      # Update current_threshold_condition_hash and call hierarchical_symptomatic_condition on each jurisdiction
      # Will pre-generate all possible thresholdConditions
      Jurisdiction.all.each do |jur|
        jur.update(current_threshold_condition_hash: jur.calculate_current_threshold_condition_hash)
        jur.hierarchical_symptomatic_condition
      end
    end
  end

  def down
    remove_column :jurisdictions, :current_threshold_condition_hash, :string
  end
end

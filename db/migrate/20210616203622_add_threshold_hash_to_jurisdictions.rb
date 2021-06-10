class AddThresholdHashToJurisdictions < ActiveRecord::Migration[6.1]
  def up
    add_column :jurisdictions, :current_threshold_condition_hash, :string

    # populate :current_threshold_condition_hash
    Jurisdiction.all.find_each do |jur|
      jur.update(current_threshold_condition_hash: Digest::SHA256.hexdigest(jur[:path] + ThresholdCondition.where(jurisdiction_id: jur.path_ids).size.to_s))
    end
  end

  def down
    remove_column :jurisdictions, :current_threshold_condition_hash, :string
  end
end

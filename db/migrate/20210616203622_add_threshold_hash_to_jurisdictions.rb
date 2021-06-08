class AddThresholdHashToJurisdictions < ActiveRecord::Migration[6.1]
  def up
    add_column :jurisdictions, :threshold_hash, :string

    # populate :threshold_hash
    Jurisdiction.all.find_each do |jur|
      jur.update(threshold_hash: Digest::SHA256.hexdigest(jur[:path] + ThresholdCondition.where(jurisdiction_id: jur.path_ids).size.to_s))
    end
  end

  def down
    remove_column :jurisdictions, :threshold_hash, :string
  end
end

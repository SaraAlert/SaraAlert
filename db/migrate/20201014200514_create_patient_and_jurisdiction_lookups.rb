class CreatePatientAndJurisdictionLookups < ActiveRecord::Migration[6.0]
  def up
    create_table :patient_lookups do |t|
      t.string :old_submission_token, index: true
      t.string :new_submission_token
    end

    create_table :jurisdiction_lookups do |t|
      t.string :old_unique_identifier, index: true
      t.string :new_unique_identifier
    end

    # generate new submission tokens for existing patients and populate lookup table
    ActiveRecord::Base.transaction do
      Patient.where(purged: false).find_each do |patient|
        new_submission_token = nil
        loop do
          # create a unique, random, 10 character, url-safe, base-64 string
          new_submission_token = SecureRandom.urlsafe_base64[0, 10]
        break unless PatientLookup.where(new_submission_token: new_submission_token).any?
        end
        patient_lookup = PatientLookup.new(old_submission_token: patient.submission_token, new_submission_token: new_submission_token)
        patient_lookup.save
        patient.update(submission_token: new_submission_token)
      end
    end

    # generate new unique identifiers for existing jurisdictions and populate lookup table
    ActiveRecord::Base.transaction do
      Jurisdiction.find_each do |jurisdiction|
        # create a 10 character, url-safe, base-64 string based on the SHA-256 hash of the jurisdiction path
        new_unique_identifier = Base64::urlsafe_encode64([[Digest::SHA256.hexdigest(jurisdiction[:path])].pack('H*')].pack('m0'))[0, 10]
        # warn user if collision has occured
        if Jurisdiction.where(unique_identifier: new_unique_identifier).any?
          puts "JURISDICTION IDENTIFIER HASH COLLISION FOR: #{jurisdiction[:path]}"
        end
        jurisdiction_lookup = JurisdictionLookup.new(old_unique_identifier: jurisdiction.unique_identifier, new_unique_identifier: new_unique_identifier)
        jurisdiction_lookup.save
        jurisdiction.update(unique_identifier: new_unique_identifier)
      end
    end
  end

  def down
    # replace new submission tokens with old ones from lookup table
    ActiveRecord::Base.transaction do
      PatientLookup.find_each do |patient_lookup|
        patient = Patient.where(submission_token: patient_lookup.new_submission_token).first
        patient.update(submission_token: patient_lookup.old_submission_token)
      end
    end

    # replace new unique identifiers with old old ones from lookup table
    ActiveRecord::Base.transaction do
      JurisdictionLookup.find_each do |jurisdiction_lookup|
        jurisdiction = Jurisdiction.where(unique_identifier: jurisdiction_lookup.new_unique_identifier).first
        jurisdiction.update(unique_identifier: jurisdiction_lookup.old_unique_identifier)
      end
    end

    drop_table :patient_lookups
    drop_table :jurisdiction_lookups
  end
end

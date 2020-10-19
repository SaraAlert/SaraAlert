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

    # Generate new submission tokens for existing patients and populate lookup table
    puts 'Generating new patient submission tokens...'
    ActiveRecord::Base.transaction do
      Patient.where(purged: false).find_each do |patient|
        # Create a unique, random, 10 character, url-safe, base-64 string
        new_submission_token = nil
        loop do
          new_submission_token = SecureRandom.urlsafe_base64[0, 10]
        break unless PatientLookup.where('BINARY new_submission_token = ?', new_submission_token).any?
        end

        # Update assessment receipt with new submission token if applicable
        assessment_receipt = AssessmentReceipt.where('BINARY submission_token = ?', patient.submission_token).first
        assessment_receipt.update(submission_token: new_submission_token) unless assessment_receipt.nil?

        # Create patient lookup
        patient_lookup = PatientLookup.new(old_submission_token: patient.submission_token, new_submission_token: new_submission_token)
        patient_lookup.save
        patient.update(submission_token: new_submission_token)
      end
    end

    # Generate new unique identifiers for existing jurisdictions and populate lookup table
    puts 'Generating new jurisdiction unique identifiers...'
    ActiveRecord::Base.transaction do
      Jurisdiction.find_each do |jurisdiction|
        # Create a 10 character, url-safe, base-64 string based on the SHA-256 hash of the jurisdiction path
        new_unique_identifier = Base64::urlsafe_encode64([[Digest::SHA256.hexdigest(jurisdiction[:path])].pack('H*')].pack('m0'))[0, 10]

        # Warn user if collision has occured
        if Jurisdiction.where('BINARY unique_identifier = ?', new_unique_identifier).where.not(id: jurisdiction.id).any?
          puts "JURISDICTION IDENTIFIER HASH COLLISION FOR: #{jurisdiction[:path]}"
        end

        jurisdiction_lookup = JurisdictionLookup.new(old_unique_identifier: jurisdiction.unique_identifier, new_unique_identifier: new_unique_identifier)
        jurisdiction_lookup.save
        jurisdiction.update(unique_identifier: new_unique_identifier)
      end
    end
  end

  def down
    # Replace new submission tokens with old ones from lookup table
    puts 'Restoring old patient submission tokens...'
    ActiveRecord::Base.transaction do
      PatientLookup.find_each do |patient_lookup|
        patient = Patient.where('BINARY submission_token = ?', patient_lookup.new_submission_token).first
        patient.update(submission_token: patient_lookup.old_submission_token)

        # Update assessment receipt with old submission token if applicable
        assessment_receipt = AssessmentReceipt.where('BINARY submission_token = ?', patient_lookup.new_submission_token).first
        assessment_receipt.update(submission_token: patient_lookup.old_submission_token) unless assessment_receipt.nil?
      end
    end

    # Replace new unique identifiers with old old ones from lookup table
    puts 'Restoring old jurisdiction unique identifiers...'
    ActiveRecord::Base.transaction do
      Jurisdiction.find_each do |jurisdiction|
        jurisdiction.update(unique_identifier: Digest::SHA256.hexdigest(jurisdiction.jurisdiction_path_string))
      end
    end

    drop_table :patient_lookups
    drop_table :jurisdiction_lookups
  end
end

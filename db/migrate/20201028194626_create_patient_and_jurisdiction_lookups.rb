class CreatePatientAndJurisdictionLookups < ActiveRecord::Migration[6.0]
  def up
    create_table :patient_lookups do |t|
      t.string :old_submission_token, index: true
      t.string :new_submission_token, index: true
    end

    create_table :jurisdiction_lookups do |t|
      t.string :old_unique_identifier, index: true
      t.string :new_unique_identifier
    end

    # Generate new submission tokens for existing patients and populate lookup table
    puts 'Generating new patient submission tokens...'
    ActiveRecord::Base.transaction do
      # Create patient submission tokens in bulk for performance and check for duplicates later
      Patient.where.not(submission_token: nil).find_in_batches(batch_size: 1000).with_index do |patients_group, batch|
        puts "  Processing batch #{batch + 1}"
        submission_tokens = patients_group.pluck(:id, :submission_token)

        # Create unique, random, 10 character, url-safe, base-64 strings
        patient_lookups = submission_tokens.map.with_index do |(id, submission_token), index|
          { old_submission_token: submission_token, new_submission_token: SecureRandom.urlsafe_base64[0, 10] }
        end

        # Populate lookup table
        PatientLookup.import(patient_lookups)
      end

      # Check for duplicates and generate new submission tokens individually if necessary
      puts '  Checking for duplicates:'
      duplicate_tokens = PatientLookup.select(:new_submission_token).group(:new_submission_token).having('COUNT(*) > 1').pluck(:new_submission_token)
      if duplicate_tokens.empty?
        puts '    NO DUPLICATES DETECTED'
      else
        PatientLookup.where(new_submission_token: duplicate_tokens).find_each do |patient_lookup|
          puts "    REGENERATING SUBMISSION TOKEN FOR DUPLICATE TOKEN: #{patient_lookup[:new_submission_token]}"
          # Create a unique, random, 10 character, url-safe, base-64 string
          new_submission_token = nil
          loop do
            new_submission_token = SecureRandom.urlsafe_base64[0, 10]
          break unless PatientLookup.where(new_submission_token: new_submission_token).any?
          end

          # Update patient lookup
          PatientLookup.where(new_submission_token: patient.submission_token).update(new_submission_token: new_submission_token)
        end
      end

      # Update assessment receipts with new submission tokens
      execute <<-SQL.squish
        UPDATE assessment_receipts
        INNER JOIN (
          SELECT old_submission_token, new_submission_token
          FROM patient_lookups
        ) t ON assessment_receipts.submission_token = t.old_submission_token
        SET assessment_receipts.submission_token = t.new_submission_token
      SQL

      # Update patients with new submission tokens
      execute <<-SQL.squish
        UPDATE patients
        INNER JOIN (
          SELECT old_submission_token, new_submission_token
          FROM patient_lookups
        ) t ON patients.submission_token = t.old_submission_token
        SET patients.submission_token = t.new_submission_token
      SQL
    end

    # Generate new unique identifiers for existing jurisdictions and populate lookup table
    puts 'Generating new jurisdiction unique identifiers...'
    ActiveRecord::Base.transaction do
      jurisdiction_paths_and_identifiers = Jurisdiction.all.pluck(:id, :path, :unique_identifier)

      # Create new unique identifiers (10 character, url-safe, base-64 strings based on the SHA-256 hash of the jurisdiction paths)
      puts '  Computing hashes...'
      new_unique_identifiers = jurisdiction_paths_and_identifiers.collect(&:second).map do |path|
        Base64::urlsafe_encode64([[Digest::SHA256.hexdigest(path)].pack('H*')].pack('m0'))[0, 10]
      end

      # Check for collisions
      puts '  Checking for collisions:'
      duplicates = new_unique_identifiers.group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)
      if duplicates.empty?
        puts "    NO COLLISIONS DETECTED"
      else
        new_unique_identifiers.each_with_index do |new_unique_identifier, index|
          if duplicates.include?(new_unique_identifier)
            puts "    JURISDICTION IDENTIFIER HASH COLLISION FOR: #{jurisdiction_paths_and_identifiers[index][1]} (#{new_unique_identifier})"
          end
        end
      end

      # Populate lookup table
      puts '  Populating lookup table...'
      jurisdiction_lookups = jurisdiction_paths_and_identifiers.map.with_index do |(id, path, identifier), index|
        { old_unique_identifier: identifier, new_unique_identifier: new_unique_identifiers[index] }
      end
      JurisdictionLookup.import(jurisdiction_lookups)

      # Update jurisdictions with new unique identifiers
      execute <<-SQL.squish
        UPDATE jurisdictions
        INNER JOIN (
          SELECT old_unique_identifier, new_unique_identifier
          FROM jurisdiction_lookups
        ) t ON jurisdictions.unique_identifier = t.old_unique_identifier
        SET jurisdictions.unique_identifier = t.new_unique_identifier
      SQL
    end
  end

  def down
    puts 'Restoring old patient submission tokens...'
    ActiveRecord::Base.transaction do
      # Update assessment receipts with old submission tokens
      execute <<-SQL.squish
        UPDATE assessment_receipts
        INNER JOIN (
          SELECT old_submission_token, new_submission_token
          FROM patient_lookups
        ) t ON assessment_receipts.submission_token = t.new_submission_token
        SET assessment_receipts.submission_token = t.old_submission_token
      SQL

      # Update patients with old submission tokens
      execute <<-SQL.squish
        UPDATE patients
        INNER JOIN (
          SELECT old_submission_token, new_submission_token
          FROM patient_lookups
        ) t ON patients.submission_token = t.new_submission_token
        SET patients.submission_token = t.old_submission_token
      SQL
    end

    puts 'Restoring old jurisdiction unique identifiers...'
    ActiveRecord::Base.transaction do
      # Update jurisdictions with old unique identifiers
      execute <<-SQL.squish
        UPDATE jurisdictions
        INNER JOIN (
          SELECT old_unique_identifier, new_unique_identifier
          FROM jurisdiction_lookups
        ) t ON jurisdictions.unique_identifier = t.new_unique_identifier
        SET jurisdictions.unique_identifier = t.old_unique_identifier
      SQL
    end

    drop_table :patient_lookups
    drop_table :jurisdiction_lookups
  end
end

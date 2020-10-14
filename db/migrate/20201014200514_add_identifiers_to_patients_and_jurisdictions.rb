class AddIdentifiersToPatientsAndJurisdictions < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.transaction do
      add_column :patients, :patient_identifier, :string, index: true
      add_column :jurisdictions, :jurisdiction_identifier, :string, index: true
      add_column :assessment_receipts, :patient_identifier, :string, index: true

      # populate :patient_identifier for existing patients
      Patient.where(purged: false).find_each do |patient|
        patient_identifier = nil
        loop do
          # create a unique, random, 10 character, url-safe, base-64 string
          patient_identifier = SecureRandom.urlsafe_base64[0, 10]
        break unless Patient.where(patient_identifier: patient_identifier).any?
        end
        patient.update(patient_identifier: patient_identifier)
      end

      # populate :jurisdiction_identifier for existing jurisdictions
      Jurisdiction.find_each do |jurisdiction|
        # create a 10 character, url-safe, base-64 string based on the SHA-256 hash of the jurisdiction path
        jurisdiction_identifier = [[Digest::SHA256.hexdigest(jurisdiction[:path])].pack('H*')].pack('m0')[0, 10]
        # warn user if collision has occured
        if Jurisdiction.where(jurisdiction_identifier: jurisdiction_identifier).any?
          puts "JURISDICTION IDENTIFIER HASH COLLISION FOR: #{jurisdiction[:path]}"
        end
        jurisdiction.update(jurisdiction_identifier: jurisdiction_identifier)
      end
    end
  end

  def down
    remove_column :patients, :patient_identifier, :string
    remove_column :jurisdictions, :jurisdiction_identifier, :string
    remove_column :assessment_receipts, :patient_identifier, :string
  end
end

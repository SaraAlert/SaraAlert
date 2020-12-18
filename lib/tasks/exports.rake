# frozen_string_literal: true

namespace :exports do
  desc 'Export record to PHDC format'
  task patient_to_phdc: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
    patient_id = ENV['ID']
    unless Patient.exists?(patient_id)
      puts "Error: Patient with id #{patient_id} not found"
      exit
    end
    patient = Patient.find(patient_id)
    phdc_converter = PHDC::Serializer.new
    puts Nokogiri.XML(phdc_converter.patient_to_phdc(patient, patient.jurisdiction, patient.assessments.where(symptomatic: true))).to_xml(:indent => 2)
  end

  desc 'Export all records to PHDC format'
  task patients_to_phdc: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    phdc_converter = PHDC::Serializer.new

    zip = phdc_converter.patients_to_phdc_zip(Patient.select('id,updated_at,address_line_1,address_city,address_state,address_county,
                                                              primary_telephone,first_name,middle_name,last_name,sex,white,
                                                              black_or_african_american,american_indian_or_alaska_native,asian,
                                                              native_hawaiian_or_other_pacific_islander,ethnicity,address_zip,
                                                              date_of_birth,secondary_telephone, created_at, primary_language,
                                                              user_defined_id_statelocal, gender_identity, potential_exposure_country,
                                                              potential_exposure_location, exposure_notes').all, Jurisdiction.first)
    nbs_filename = "NBS-#{DateTime.now.to_s}.zip"
    File.open(nbs_filename, 'w') { |file| file.write(zip.string) }
    puts "Saved export file to: #{nbs_filename}"
  end
end

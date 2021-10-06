class UpdatePatientTableStringLengths < ActiveRecord::Migration[6.1]
  STRING_FIELDS = [
    # Identification
    :first_name,
    :last_name,
    :middle_name,
    :sex,
    :gender_identity,
    :sexual_orientation,
    :ethnicity,
    :nationality,
    :primary_language,
    :secondary_language,
    :user_defined_id_statelocal,
    :user_defined_id_cdc,
    :user_defined_id_nndss,

    # Address
    :address_line_1,
    :address_line_2,
    :address_city,
    :address_state,
    :address_zip,
    :address_county,
    :foreign_address_line_1,
    :foreign_address_line_2,
    :foreign_address_city,
    :foreign_address_country,
    :foreign_address_zip,
    :foreign_address_line_3,
    :foreign_address_state,
    :monitored_address_line_1,
    :monitored_address_line_2,
    :monitored_address_city,
    :monitored_address_state,
    :monitored_address_zip,
    :monitored_address_county,
    :foreign_monitored_address_line_1,
    :foreign_monitored_address_line_2,
    :foreign_monitored_address_city,
    :foreign_monitored_address_state,
    :foreign_monitored_address_zip,
    :foreign_monitored_address_county,

    # Contact
    :preferred_contact_method,
    :preferred_contact_time,
    :primary_telephone,
    :primary_telephone_type,
    :secondary_telephone,
    :secondary_telephone_type,
    :international_telephone,
    :email,

    # Arrival
    :port_of_origin,
    :flight_or_vessel_number,
    :flight_or_vessel_carrier,
    :port_of_entry_into_usa,
    :source_of_report,
    :source_of_report_specify,

    # Additional Planned Travel
    :additional_planned_travel_type,
    :additional_planned_travel_destination,
    :additional_planned_travel_destination_state,
    :additional_planned_travel_destination_country,
    :additional_planned_travel_port_of_departure,

    # Exposure
    :potential_exposure_location,
    :potential_exposure_country,
    :contact_of_known_case_id,
    :was_in_health_care_facility_with_known_cases_facility_name,
    :laboratory_personnel_facility_name,
    :healthcare_personnel_facility_name,
    :member_of_a_common_exposure_cohort_type,

    # Monitoring
    :exposure_risk_assessment,
    :monitoring_plan,
    :case_status,
    :public_health_action,
    :monitoring_reason,
    :follow_up_reason,

    # Other
    :legacy_primary_language,
    :legacy_secondary_language,
    :time_zone
  ]

  BINARY_FIELDS = %i[submission_token]

  OLD_LIMIT = 255
  NEW_LIMIT = 200

  def remove_current_indexes
    remove_index :patients, name: "index_patients_on_assigned_user"
    remove_index :patients, name: "index_patients_on_creator_id"
    remove_index :patients, name: "index_patients_on_date_of_birth"
    remove_index :patients, name: "index_patients_on_first_name"
    remove_index :patients, name: "index_patients_on_id"
    remove_index :patients, name: "index_patients_on_jurisdiction_id"
    remove_index :patients, name: "index_patients_on_last_date_of_exposure"
    remove_index :patients, name: "index_patients_on_potential_exposure_country"
    remove_index :patients, name: "index_patients_on_public_health_action"
    remove_index :patients, name: "index_patients_on_purged"
    remove_index :patients, name: "index_patients_on_responder_id"
    remove_index :patients, name: "index_patients_on_sex"
    remove_index :patients, name: "index_patients_on_submission_token"
    remove_index :patients, name: "index_patients_on_user_defined_id_cdc"
    remove_index :patients, name: "index_patients_on_user_defined_id_nndss"
    remove_index :patients, name: "index_patients_on_user_defined_id_statelocal"
    remove_index :patients, name: "patients_index_chain_1"
    remove_index :patients, name: "patients_index_chain_2"
    remove_index :patients, name: "patients_index_chain_3"
    remove_index :patients, name: "patients_index_chain_4"
    remove_index :patients, name: "patients_index_chain_5"
    remove_index :patients, name: "patients_index_chain_6"
    remove_index :patients, name: "patients_index_chain_7"
    remove_index :patients, name: "patients_index_chain_8"
    remove_index :patients, name: "patients_index_chain_two_1"
    remove_index :patients, name: "patients_index_chain_two_2"
    remove_index :patients, name: "patients_index_chain_three_1"
  end

  def add_current_indexes
    add_index :patients, :assigned_user
    add_index :patients, :creator_id
    add_index :patients, :date_of_birth
    add_index :patients, :first_name
    add_index :patients, :id
    add_index :patients, :jurisdiction_id
    add_index :patients, :last_date_of_exposure
    add_index :patients, :potential_exposure_country
    add_index :patients, :public_health_action
    add_index :patients, :purged
    add_index :patients, :responder_id
    add_index :patients, :sex
    add_index :patients, :submission_token
    add_index :patients, :user_defined_id_cdc
    add_index :patients, :user_defined_id_nndss
    add_index :patients, :user_defined_id_statelocal
    add_index :patients, [:monitoring, :purged, :public_health_action, :isolation, :jurisdiction_id], name: 'patients_index_chain_1'
    add_index :patients, [:monitoring, :purged, :isolation, :jurisdiction_id], name: 'patients_index_chain_2'
    add_index :patients, [:last_name, :first_name], name: 'patients_index_chain_3'
    add_index :patients, [:id, :monitoring, :purged, :isolation, :symptom_onset], name: 'patients_index_chain_4'
    add_index :patients, [:monitoring, :purged, :isolation, :id, :public_health_action], name: 'patients_index_chain_5'
    add_index :patients, [:isolation, :jurisdiction_id], name: 'patients_index_chain_6'
    add_index :patients, [:monitoring, :purged, :isolation], name: 'patients_index_chain_7'
    add_index :patients, [:jurisdiction_id, :assigned_user], name: 'patients_index_chain_8'
    add_index :patients, [:primary_telephone, :responder_id, :id, :jurisdiction_id], name: 'patients_index_chain_two_1'
    add_index :patients, [:email, :responder_id, :id, :jurisdiction_id], name: 'patients_index_chain_two_2'
    add_index :patients, [:jurisdiction_id, :isolation, :purged, :assigned_user], name: 'patients_index_chain_three_1'
  end

  # NOTE: removing and adding indexes significantly improves performance

  def up
    STRING_FIELDS.each do |field|
      if Patient.where("length(#{field}) > 200").exists?
        raise StandardError.new "Deteced string value over 200 characters in column #{field}. Aborting migration."
      end
    end

    ActiveRecord::Base.record_timestamps = false
    remove_current_indexes

    begin
      STRING_FIELDS.each { |field| change_column :patients, field, :string, limit: NEW_LIMIT }
      BINARY_FIELDS.each { |field| change_column :patients, field, :binary, limit: NEW_LIMIT }
    ensure
      add_current_indexes
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    remove_current_indexes

    begin
      STRING_FIELDS.each { |field| change_column :patients, field, :string, limit: OLD_LIMIT }
      BINARY_FIELDS.each { |field| change_column :patients, field, :binary, limit: OLD_LIMIT }
    ensure
      add_current_indexes
      ActiveRecord::Base.record_timestamps = true
    end
  end
end

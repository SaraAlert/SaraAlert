class CreatePatients < ActiveRecord::Migration[6.0]
  def change
    create_table :patients do |t|
      t.timestamps
      t.integer :responder_id, index: true
      t.integer :creator_id, index: true
      t.integer :jurisdiction_id, index: true
      t.string :submission_token, index: true

      # Monitoring represents if a monitoree is open and being currently being monitored
      t.boolean :monitoring, default: true, index: true
      t.string :monitoring_reason # Reason for monitoring status

      # Has this record been purged
      t.boolean :purged, default: false, index: true

      # Workflow categories
      t.string :exposure_risk_assessment
      t.string :monitoring_plan, default: 'None'

      # Latest public health action
      t.string :public_health_action, default: 'None', index: true

      # DateTime of last assessment reminder sent
      t.datetime :last_assessment_reminder_sent

      # User definable identifier (STATE/LOCAL)
      t.string :user_defined_id_statelocal, index: true
      # User definable identifier (CDC)
      t.string :user_defined_id_cdc
      # User definable identifier (NNDSS)
      t.string :user_defined_id_nndss

      # Data collected for each patient
      t.string :first_name, index: true
      t.string :middle_name
      t.string :last_name, index: true
      t.date :date_of_birth, index: true
      t.integer :age
      t.string :sex, index: true
      t.boolean :white
      t.boolean :black_or_african_american
      t.boolean :american_indian_or_alaska_native
      t.boolean :asian
      t.boolean :native_hawaiian_or_other_pacific_islander
      t.string :ethnicity
      t.string :primary_language
      t.string :secondary_language
      t.boolean :interpretation_required
      t.string :nationality
      t.string :address_line_1
      t.string :foreign_address_line_1
      t.string :address_city
      t.string :address_state
      t.string :address_line_2
      t.string :address_zip
      t.string :address_county
      t.string :monitored_address_line_1
      t.string :monitored_address_city
      t.string :monitored_address_state
      t.string :monitored_address_line_2
      t.string :monitored_address_zip
      t.string :monitored_address_county
      t.string :foreign_address_city
      t.string :foreign_address_country
      t.string :foreign_address_line_2
      t.string :foreign_address_zip
      t.string :foreign_address_line_3
      t.string :foreign_address_state
      t.string :foreign_monitored_address_line_1
      t.string :foreign_monitored_address_city
      t.string :foreign_monitored_address_state
      t.string :foreign_monitored_address_line_2
      t.string :foreign_monitored_address_zip
      t.string :foreign_monitored_address_county
      t.string :primary_telephone
      t.string :primary_telephone_type
      t.string :secondary_telephone
      t.string :secondary_telephone_type
      t.string :email
      t.string :preferred_contact_method
      t.string :preferred_contact_time
      t.string :port_of_origin
      t.string :source_of_report
      t.string :flight_or_vessel_number
      t.string :flight_or_vessel_carrier
      t.string :port_of_entry_into_usa
      t.text :travel_related_notes
      t.string :additional_planned_travel_type
      t.string :additional_planned_travel_destination
      t.string :additional_planned_travel_destination_state
      t.string :additional_planned_travel_destination_country
      t.string :additional_planned_travel_port_of_departure
      t.date :date_of_departure
      t.date :date_of_arrival
      t.date :additional_planned_travel_start_date
      t.date :additional_planned_travel_end_date
      t.text :additional_planned_travel_related_notes
      t.date :last_date_of_exposure, index: true
      t.string :potential_exposure_location
      t.string :potential_exposure_country, index: true
      t.boolean :contact_of_known_case
      t.string :contact_of_known_case_id
      t.boolean :member_of_a_common_exposure_cohort
      t.string :member_of_a_common_exposure_cohort_type
      t.boolean :travel_to_affected_country_or_area
      t.boolean :laboratory_personnel
      t.string :laboratory_personnel_facility_name
      t.boolean :healthcare_personnel
      t.string :healthcare_personnel_facility_name
      t.boolean :crew_on_passenger_or_cargo_flight
      t.boolean :was_in_health_care_facility_with_known_cases
      t.string :was_in_health_care_facility_with_known_cases_facility_name
      t.text :exposure_notes
    end
  end
end

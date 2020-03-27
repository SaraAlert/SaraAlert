# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_13_134912) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "analytics", force: :cascade do |t|
    t.integer "jurisdiction_id"
    t.integer "monitorees_count"
    t.integer "symptomatic_monitorees_count"
    t.integer "asymptomatic_monitorees_count"
    t.integer "confirmed_cases_count"
    t.integer "closed_cases_count"
    t.integer "open_cases_count"
    t.integer "total_reports_count"
    t.integer "non_reporting_monitorees_count"
    t.string "monitoree_state_map"
    t.string "symptomatic_state_map"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "assessment_receipts", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "submission_token"
  end

  create_table "assessments", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "patient_id"
    t.boolean "symptomatic"
    t.string "who_reported", default: "Monitoree"
    t.index ["patient_id"], name: "index_assessments_on_patient_id"
  end

  create_table "conditions", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "jurisdiction_id"
    t.integer "assessment_id"
    t.string "threshold_condition_hash"
    t.string "type"
  end

  create_table "histories", force: :cascade do |t|
    t.bigint "patient_id"
    t.text "comment"
    t.string "created_by"
    t.string "history_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_histories_on_patient_id"
  end

  create_table "jurisdictions", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.string "unique_identifier"
    t.string "ancestry"
    t.index ["ancestry"], name: "index_jurisdictions_on_ancestry"
  end

  create_table "patients", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "responder_id"
    t.integer "creator_id"
    t.integer "jurisdiction_id"
    t.string "submission_token"
    t.boolean "monitoring", default: true
    t.string "monitoring_reason"
    t.boolean "purged", default: false
    t.string "exposure_risk_assessment"
    t.string "monitoring_plan"
    t.string "public_health_action", default: "None"
    t.datetime "last_assessment_reminder_sent"
    t.string "user_defined_id_statelocal"
    t.string "user_defined_id_cdc"
    t.string "user_defined_id_nndss"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.integer "age"
    t.string "sex"
    t.boolean "white"
    t.boolean "black_or_african_american"
    t.boolean "american_indian_or_alaska_native"
    t.boolean "asian"
    t.boolean "native_hawaiian_or_other_pacific_islander"
    t.string "ethnicity"
    t.string "primary_language"
    t.string "secondary_language"
    t.boolean "interpretation_required"
    t.string "nationality"
    t.string "address_line_1"
    t.string "foreign_address_line_1"
    t.string "address_city"
    t.string "address_state"
    t.string "address_line_2"
    t.string "address_zip"
    t.string "address_county"
    t.string "monitored_address_line_1"
    t.string "monitored_address_city"
    t.string "monitored_address_state"
    t.string "monitored_address_line_2"
    t.string "monitored_address_zip"
    t.string "monitored_address_county"
    t.string "foreign_address_city"
    t.string "foreign_address_country"
    t.string "foreign_address_line_2"
    t.string "foreign_address_zip"
    t.string "foreign_address_line_3"
    t.string "foreign_address_state"
    t.string "foreign_monitored_address_line_1"
    t.string "foreign_monitored_address_city"
    t.string "foreign_monitored_address_state"
    t.string "foreign_monitored_address_line_2"
    t.string "foreign_monitored_address_zip"
    t.string "foreign_monitored_address_county"
    t.string "primary_telephone"
    t.string "primary_telephone_type"
    t.string "secondary_telephone"
    t.string "secondary_telephone_type"
    t.string "email"
    t.string "preferred_contact_method"
    t.string "preferred_contact_time"
    t.string "port_of_origin"
    t.string "source_of_report"
    t.string "flight_or_vessel_number"
    t.string "flight_or_vessel_carrier"
    t.string "port_of_entry_into_usa"
    t.text "travel_related_notes"
    t.string "additional_planned_travel_type"
    t.string "additional_planned_travel_destination"
    t.string "additional_planned_travel_destination_state"
    t.string "additional_planned_travel_destination_country"
    t.string "additional_planned_travel_port_of_departure"
    t.date "date_of_departure"
    t.date "date_of_arrival"
    t.date "additional_planned_travel_start_date"
    t.date "additional_planned_travel_end_date"
    t.text "additional_planned_travel_related_notes"
    t.date "last_date_of_exposure"
    t.string "potential_exposure_location"
    t.string "potential_exposure_country"
    t.boolean "contact_of_known_case"
    t.string "contact_of_known_case_id"
    t.boolean "member_of_a_common_exposure_cohort"
    t.string "member_of_a_common_exposure_cohort_type"
    t.boolean "travel_to_affected_country_or_area"
    t.boolean "laboratory_personnel"
    t.string "laboratory_personnel_facility_name"
    t.boolean "healthcare_personnel"
    t.string "healthcare_personnel_facility_name"
    t.boolean "crew_on_passenger_or_cargo_flight"
    t.boolean "was_in_health_care_facility_with_known_cases"
    t.string "was_in_health_care_facility_with_known_cases_facility_name"
    t.text "exposure_notes"
    t.index ["creator_id"], name: "index_patients_on_creator_id"
    t.index ["first_name"], name: "index_patients_on_first_name"
    t.index ["jurisdiction_id"], name: "index_patients_on_jurisdiction_id"
    t.index ["last_name"], name: "index_patients_on_last_name"
    t.index ["monitoring"], name: "index_patients_on_monitoring"
    t.index ["public_health_action"], name: "index_patients_on_public_health_action"
    t.index ["purged"], name: "index_patients_on_purged"
    t.index ["responder_id"], name: "index_patients_on_responder_id"
    t.index ["submission_token"], name: "index_patients_on_submission_token"
    t.index ["user_defined_id_statelocal"], name: "index_patients_on_user_defined_id_statelocal"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "symptoms", force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.string "notes"
    t.boolean "bool_value"
    t.float "float_value"
    t.integer "int_value"
    t.integer "condition_id"
    t.string "type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transfers", force: :cascade do |t|
    t.bigint "patient_id"
    t.integer "to_jurisdiction_id"
    t.integer "from_jurisdiction_id"
    t.integer "who_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["from_jurisdiction_id"], name: "index_transfers_on_from_jurisdiction_id"
    t.index ["patient_id"], name: "index_transfers_on_patient_id"
    t.index ["to_jurisdiction_id"], name: "index_transfers_on_to_jurisdiction_id"
    t.index ["who_id"], name: "index_transfers_on_who_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.boolean "force_password_change"
    t.integer "jurisdiction_id"
    t.datetime "password_changed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jurisdiction_id"], name: "index_users_on_jurisdiction_id"
    t.index ["password_changed_at"], name: "index_users_on_password_changed_at"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

end

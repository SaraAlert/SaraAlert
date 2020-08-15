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

ActiveRecord::Schema.define(version: 2020_08_15_213502) do

  create_table "analytics", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "jurisdiction_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["jurisdiction_id", "created_at", "id"], name: "analytics_index_chain_1"
  end

  create_table "assessment_receipts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "submission_token"
    t.index ["submission_token"], name: "index_assessment_receipts_on_submission_token"
  end

  create_table "assessments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "patient_id"
    t.boolean "symptomatic"
    t.string "who_reported", default: "Monitoree"
    t.index ["created_at"], name: "assessments_index_chain_1"
    t.index ["patient_id", "created_at"], name: "assessments_index_chain_3"
    t.index ["symptomatic", "patient_id", "created_at"], name: "assessments_index_chain_2"
  end

  create_table "close_contacts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "first_name"
    t.string "last_name"
    t.string "primary_telephone"
    t.string "email"
    t.text "notes"
    t.integer "enrolled_id"
    t.integer "contact_attempts"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_close_contacts_on_patient_id"
  end

  create_table "conditions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "jurisdiction_id"
    t.integer "assessment_id"
    t.string "threshold_condition_hash"
    t.string "type"
    t.index ["assessment_id"], name: "index_conditions_on_assessment_id"
    t.index ["type", "assessment_id"], name: "conditions_index_chain_1"
    t.index ["type", "threshold_condition_hash", "id"], name: "conditions_index_chain_2"
  end

  create_table "downloads", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.binary "contents", size: :long, null: false
    t.string "lookup", null: false
    t.string "filename", null: false
    t.string "export_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "export_receipts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.string "export_type", null: false
    t.index ["user_id"], name: "index_export_receipts_on_user_id"
  end

  create_table "histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.text "comment"
    t.string "created_by"
    t.string "history_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_histories_on_patient_id"
  end

  create_table "jurisdictions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.string "unique_identifier"
    t.string "ancestry"
    t.string "path"
    t.string "phone"
    t.string "email"
    t.string "webpage"
    t.string "message"
    t.index ["ancestry"], name: "index_jurisdictions_on_ancestry"
  end

  create_table "laboratories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "lab_type"
    t.date "specimen_collection"
    t.date "report"
    t.string "result"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_laboratories_on_patient_id"
    t.index ["result", "patient_id"], name: "laboratories_index_chain_1"
  end

  create_table "monitoree_counts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "analytic_id"
    t.boolean "active_monitoring"
    t.string "category_type"
    t.string "category"
    t.string "risk_level"
    t.integer "total"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["analytic_id"], name: "index_monitoree_counts_on_analytic_id"
  end

  create_table "monitoree_maps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "analytic_id"
    t.string "level"
    t.string "workflow"
    t.string "state"
    t.string "county"
    t.integer "total"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["analytic_id"], name: "index_monitoree_maps_on_analytic_id"
  end

  create_table "monitoree_snapshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "analytic_id"
    t.string "time_frame"
    t.integer "new_enrollments"
    t.integer "transferred_in"
    t.integer "closed"
    t.integer "transferred_out"
    t.integer "referral_for_medical_evaluation"
    t.integer "document_completed_medical_evaluation"
    t.integer "document_medical_evaluation_summary_and_plan"
    t.integer "referral_for_public_health_test"
    t.integer "public_health_test_specimen_received_by_lab_results_pending"
    t.integer "results_of_public_health_test_positive"
    t.integer "results_of_public_health_test_negative"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["analytic_id"], name: "index_monitoree_snapshots_on_analytic_id"
  end

  create_table "oauth_access_grants", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "old_passwords", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "patients", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "monitoring_plan", default: "None"
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
    t.boolean "isolation", default: false
    t.datetime "closed_at"
    t.string "source_of_report_specify"
    t.boolean "pause_notifications", default: false
    t.date "symptom_onset"
    t.string "case_status"
    t.integer "assigned_user"
    t.boolean "continuous_exposure", default: false
    t.datetime "latest_assessment_at"
    t.datetime "latest_fever_or_fever_reducer_at"
    t.date "latest_positive_lab_at"
    t.integer "negative_lab_count", default: 0
    t.datetime "latest_transfer_at"
    t.integer "latest_transfer_from"
    t.string "gender_identity"
    t.string "sexual_orientation"
    t.boolean "user_defined_symptom_onset"
    t.index ["assigned_user"], name: "index_patients_on_assigned_user"
    t.index ["creator_id"], name: "index_patients_on_creator_id"
    t.index ["date_of_birth"], name: "index_patients_on_date_of_birth"
    t.index ["email", "responder_id", "id", "jurisdiction_id"], name: "patients_index_chain_two_2"
    t.index ["first_name"], name: "index_patients_on_first_name"
    t.index ["id", "monitoring", "purged", "isolation", "symptom_onset"], name: "patients_index_chain_4"
    t.index ["id"], name: "index_patients_on_id"
    t.index ["isolation", "jurisdiction_id"], name: "patients_index_chain_6"
    t.index ["jurisdiction_id"], name: "index_patients_on_jurisdiction_id"
    t.index ["last_date_of_exposure"], name: "index_patients_on_last_date_of_exposure"
    t.index ["last_name", "first_name"], name: "patients_index_chain_3"
    t.index ["monitoring", "purged", "isolation", "id", "public_health_action"], name: "patients_index_chain_5"
    t.index ["monitoring", "purged", "isolation", "jurisdiction_id"], name: "patients_index_chain_2"
    t.index ["monitoring", "purged", "isolation"], name: "patients_index_chain_7"
    t.index ["monitoring", "purged", "public_health_action", "isolation", "jurisdiction_id"], name: "patients_index_chain_1"
    t.index ["potential_exposure_country"], name: "index_patients_on_potential_exposure_country"
    t.index ["primary_telephone", "responder_id", "id", "jurisdiction_id"], name: "patients_index_chain_two_1"
    t.index ["public_health_action"], name: "index_patients_on_public_health_action"
    t.index ["purged"], name: "index_patients_on_purged"
    t.index ["responder_id"], name: "index_patients_on_responder_id"
    t.index ["sex"], name: "index_patients_on_sex"
    t.index ["submission_token"], name: "index_patients_on_submission_token"
    t.index ["user_defined_id_cdc"], name: "index_patients_on_user_defined_id_cdc"
    t.index ["user_defined_id_nndss"], name: "index_patients_on_user_defined_id_nndss"
    t.index ["user_defined_id_statelocal"], name: "index_patients_on_user_defined_id_statelocal"
  end

  create_table "roles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "symptoms", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.boolean "required", default: true
    t.string "threshold_operator", default: "Less Than"
    t.integer "group", default: 1
    t.index ["condition_id"], name: "index_symptoms_on_condition_id"
    t.index ["name", "bool_value", "condition_id"], name: "symptoms_index_chain_1"
  end

  create_table "transfers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "authy_id"
    t.datetime "last_sign_in_with_authy"
    t.boolean "authy_enabled", default: false
    t.boolean "authy_enforced", default: true
    t.boolean "api_enabled", default: false
    t.index ["authy_id"], name: "index_users_on_authy_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jurisdiction_id"], name: "index_users_on_jurisdiction_id"
    t.index ["password_changed_at"], name: "index_users_on_password_changed_at"
  end

  create_table "users_roles", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end

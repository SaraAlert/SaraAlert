# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_02_03_164307) do

  create_table "active_storage_attachments", charset: "utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics", charset: "utf8", force: :cascade do |t|
    t.bigint "jurisdiction_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["jurisdiction_id", "created_at", "id"], name: "analytics_index_chain_1"
  end

  create_table "api_downloads", charset: "utf8", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.string "url"
    t.string "job_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["application_id"], name: "index_api_downloads_on_application_id"
  end

  create_table "assessment_receipts", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "submission_token"
    t.index ["submission_token"], name: "index_assessment_receipts_on_submission_token"
  end

  create_table "assessments", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "patient_id"
    t.boolean "symptomatic"
    t.string "who_reported", default: "Monitoree"
    t.datetime "reported_at", precision: 6
    t.index ["created_at"], name: "assessments_index_chain_1"
    t.index ["patient_id", "created_at"], name: "assessments_index_chain_3"
    t.index ["reported_at"], name: "index_assessments_on_reported_at"
    t.index ["symptomatic", "patient_id", "created_at"], name: "assessments_index_chain_2"
  end

  create_table "audits", charset: "utf8", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "blocked_numbers", charset: "utf8", force: :cascade do |t|
    t.string "phone_number", null: false
    t.index ["phone_number"], name: "index_blocked_phone_number"
  end

  create_table "close_contacts", charset: "utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "first_name"
    t.string "last_name"
    t.string "primary_telephone"
    t.string "email"
    t.text "notes"
    t.bigint "enrolled_id"
    t.integer "contact_attempts"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "last_date_of_exposure"
    t.integer "assigned_user"
    t.index ["patient_id"], name: "index_close_contacts_on_patient_id"
  end

  create_table "common_exposure_cohorts", charset: "utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "cohort_type"
    t.string "cohort_name"
    t.string "cohort_location"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cohort_location"], name: "index_common_exposure_cohorts_on_cohort_location"
    t.index ["cohort_name"], name: "index_common_exposure_cohorts_on_cohort_name"
    t.index ["cohort_type"], name: "index_common_exposure_cohorts_on_cohort_type"
    t.index ["patient_id"], name: "index_common_exposure_cohorts_on_patient_id"
  end

  create_table "conditions", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "jurisdiction_id"
    t.bigint "assessment_id"
    t.string "threshold_condition_hash"
    t.string "type"
    t.index ["assessment_id"], name: "index_conditions_on_assessment_id"
    t.index ["type", "assessment_id"], name: "conditions_index_chain_1"
    t.index ["type", "jurisdiction_id"], name: "conditions_index_chain_3"
    t.index ["type", "threshold_condition_hash", "id"], name: "conditions_index_chain_2"
  end

  create_table "contact_attempts", charset: "utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.bigint "user_id"
    t.boolean "successful"
    t.text "note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_contact_attempts_on_patient_id"
    t.index ["successful"], name: "index_contact_attempts_on_successful"
    t.index ["user_id"], name: "index_contact_attempts_on_user_id"
  end

  create_table "downloads", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "filename", null: false
    t.string "export_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "marked_for_deletion", default: false
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "export_receipts", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.string "export_type", null: false
    t.index ["user_id"], name: "index_export_receipts_on_user_id"
  end

  create_table "histories", charset: "utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.text "comment"
    t.string "created_by"
    t.string "history_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "deleted_by"
    t.string "delete_reason"
    t.bigint "original_comment_id"
    t.index ["patient_id"], name: "index_histories_on_patient_id"
  end

  create_table "jurisdiction_lookups", charset: "utf8", force: :cascade do |t|
    t.string "old_unique_identifier"
    t.binary "new_unique_identifier", limit: 255
    t.index ["old_unique_identifier"], name: "index_jurisdiction_lookups_on_old_unique_identifier"
  end

  create_table "jurisdictions", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.binary "unique_identifier", limit: 255
    t.string "ancestry"
    t.string "path"
    t.string "phone"
    t.string "email"
    t.string "webpage"
    t.string "message"
    t.boolean "send_digest", default: false
    t.boolean "send_close", default: false
    t.string "current_threshold_condition_hash"
    t.json "custom_messages"
    t.index ["ancestry"], name: "index_jurisdictions_on_ancestry"
  end

  create_table "jwt_identifiers", charset: "utf8", force: :cascade do |t|
    t.string "value"
    t.datetime "expiration_date"
    t.bigint "application_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["application_id"], name: "index_jwt_identifiers_on_application_id"
  end

  create_table "laboratories", charset: "utf8", force: :cascade do |t|
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

  create_table "monitoree_counts", charset: "utf8", force: :cascade do |t|
    t.bigint "analytic_id"
    t.boolean "active_monitoring"
    t.string "category_type"
    t.string "category"
    t.integer "total"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status"
    t.index ["analytic_id"], name: "index_monitoree_counts_on_analytic_id"
  end

  create_table "monitoree_maps", charset: "utf8", force: :cascade do |t|
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

  create_table "monitoree_snapshots", charset: "utf8", force: :cascade do |t|
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
    t.string "status", default: "Missing"
    t.integer "exposure_to_isolation_active"
    t.integer "exposure_to_isolation_not_active"
    t.integer "cases_closed_in_exposure"
    t.integer "isolation_to_exposure"
    t.index ["analytic_id"], name: "index_monitoree_snapshots_on_analytic_id"
  end

  create_table "oauth_access_grants", charset: "utf8", force: :cascade do |t|
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

  create_table "oauth_access_tokens", charset: "utf8", force: :cascade do |t|
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

  create_table "oauth_applications", charset: "utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "public_key_set"
    t.bigint "jurisdiction_id"
    t.bigint "user_id"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "old_passwords", charset: "utf8", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "patient_lookups", charset: "utf8", force: :cascade do |t|
    t.string "old_submission_token"
    t.binary "new_submission_token", limit: 255
    t.index ["new_submission_token"], name: "index_patient_lookups_on_new_submission_token"
    t.index ["old_submission_token"], name: "index_patient_lookups_on_old_submission_token"
  end

  create_table "patients", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "responder_id"
    t.bigint "creator_id"
    t.bigint "jurisdiction_id"
    t.binary "submission_token", limit: 255
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
    t.integer "negative_lab_count", default: 0
    t.datetime "latest_transfer_at"
    t.bigint "latest_transfer_from"
    t.string "gender_identity"
    t.string "sexual_orientation"
    t.boolean "user_defined_symptom_onset"
    t.date "extended_isolation"
    t.boolean "head_of_household"
    t.string "time_zone", default: "America/New_York"
    t.boolean "race_other"
    t.boolean "race_unknown"
    t.boolean "race_refused_to_answer"
    t.boolean "latest_assessment_symptomatic", default: false
    t.date "first_positive_lab_at"
    t.string "legacy_primary_language"
    t.string "legacy_secondary_language"
    t.string "follow_up_reason"
    t.text "follow_up_note"
    t.string "international_telephone"
    t.boolean "enrolled_isolation"
    t.datetime "isolation_to_exposure_at", precision: 6
    t.datetime "exposure_to_isolation_at", precision: 6
    t.string "contact_type", limit: 200, default: "Unknown"
    t.string "contact_name", limit: 200
    t.string "alternate_contact_type", limit: 200
    t.string "alternate_contact_name", limit: 200
    t.string "alternate_preferred_contact_method", limit: 200
    t.string "alternate_preferred_contact_time", limit: 200
    t.string "alternate_primary_telephone", limit: 200
    t.string "alternate_primary_telephone_type", limit: 200
    t.string "alternate_secondary_telephone", limit: 200
    t.string "alternate_secondary_telephone_type", limit: 200
    t.string "alternate_international_telephone", limit: 200
    t.string "alternate_email", limit: 200
    t.index ["assigned_user"], name: "index_patients_on_assigned_user"
    t.index ["creator_id"], name: "index_patients_on_creator_id"
    t.index ["date_of_birth"], name: "index_patients_on_date_of_birth"
    t.index ["email", "responder_id", "id", "jurisdiction_id"], name: "patients_index_chain_two_2"
    t.index ["first_name"], name: "index_patients_on_first_name"
    t.index ["id", "monitoring", "purged", "isolation", "symptom_onset"], name: "patients_index_chain_4"
    t.index ["id"], name: "index_patients_on_id"
    t.index ["isolation", "jurisdiction_id"], name: "patients_index_chain_6"
    t.index ["jurisdiction_id", "assigned_user"], name: "patients_index_chain_8"
    t.index ["jurisdiction_id", "isolation", "purged", "assigned_user"], name: "patients_index_chain_three_1"
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

  create_table "sessions", charset: "utf8", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "stats", charset: "utf8", force: :cascade do |t|
    t.bigint "jurisdiction_id", null: false
    t.json "contents", null: false
    t.string "tag", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "symptoms", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.string "notes"
    t.boolean "bool_value"
    t.float "float_value"
    t.integer "int_value"
    t.bigint "condition_id"
    t.string "type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "required", default: true
    t.string "threshold_operator", default: "Less Than"
    t.integer "group", default: 1
    t.index ["condition_id"], name: "index_symptoms_on_condition_id"
    t.index ["name", "bool_value", "condition_id"], name: "symptoms_index_chain_1"
  end

  create_table "transfers", charset: "utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.bigint "to_jurisdiction_id"
    t.bigint "from_jurisdiction_id"
    t.bigint "who_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["from_jurisdiction_id"], name: "index_transfers_on_from_jurisdiction_id"
    t.index ["patient_id"], name: "index_transfers_on_patient_id"
    t.index ["to_jurisdiction_id"], name: "index_transfers_on_to_jurisdiction_id"
    t.index ["who_id"], name: "index_transfers_on_who_id"
  end

  create_table "user_export_presets", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.json "config", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_user_export_presets_on_user_id"
  end

  create_table "user_filters", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.json "contents", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_user_filters_on_user_id"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
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
    t.bigint "jurisdiction_id"
    t.datetime "password_changed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "authy_id"
    t.datetime "last_sign_in_with_authy"
    t.boolean "authy_enabled", default: false
    t.boolean "authy_enforced", default: true
    t.boolean "api_enabled", default: false
    t.string "role", default: "none", null: false
    t.boolean "is_api_proxy", default: false
    t.text "notes"
    t.string "manual_lock_reason"
    t.datetime "last_activity_at"
    t.index ["authy_id"], name: "index_users_on_authy_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jurisdiction_id"], name: "index_users_on_jurisdiction_id"
    t.index ["last_activity_at"], name: "index_users_on_last_activity_at"
    t.index ["password_changed_at"], name: "index_users_on_password_changed_at"
  end

  create_table "vaccines", charset: "utf8", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "group_name"
    t.string "product_name"
    t.date "administration_date"
    t.string "dose_number"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_vaccines_on_patient_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_downloads", "oauth_applications", column: "application_id"
  add_foreign_key "jwt_identifiers", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end

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

ActiveRecord::Schema.define(version: 2020_01_27_192149) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assessments", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "patient_id"
    t.boolean "symptomatic"
    t.string "temperature"
    t.boolean "felt_feverish"
    t.boolean "cough"
    t.boolean "sore_throat"
    t.boolean "difficulty_breathing"
    t.boolean "muscle_aches"
    t.boolean "headache"
    t.boolean "abdominal_discomfort"
    t.boolean "vomiting"
    t.boolean "diarrhea"
    t.index ["patient_id"], name: "index_assessments_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "responder_id"
    t.integer "creator_id"
    t.string "submission_token"
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
    t.boolean "interpretation_required"
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
    t.string "port_of_origin"
    t.string "source_of_report"
    t.string "flight_or_vessel_number"
    t.string "flight_or_vessel_carrier"
    t.string "port_of_entry_into_usa"
    t.text "travel_related_notes"
    t.string "additional_planned_travel_type"
    t.string "additional_planned_travel_destination"
    t.string "additional_planned_travel_destination_state"
    t.string "additional_planned_travel_port_of_departure"
    t.date "date_of_departure"
    t.date "date_of_arrival"
    t.date "additional_planned_travel_start_date"
    t.date "additional_planned_travel_end_date"
    t.text "additional_planned_travel_related_notes"
    t.date "last_date_of_potential_exposure"
    t.string "potential_exposure_location"
    t.string "potential_exposure_country"
    t.boolean "contact_of_known_case"
    t.string "contact_of_known_case_id"
    t.boolean "healthcare_worker"
    t.boolean "worked_in_health_care_facility"
    t.index ["creator_id"], name: "index_patients_on_creator_id"
    t.index ["responder_id"], name: "index_patients_on_responder_id"
    t.index ["submission_token"], name: "index_patients_on_submission_token"
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

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

end

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

ActiveRecord::Schema[8.0].define(version: 2025_08_04_190100) do
  create_table "claimants", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.string "full_name"
    t.string "email"
    t.string "phone"
    t.date "date_of_birth"
    t.string "ssn"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_claimants_on_claim_id"
  end

  create_table "claims", force: :cascade do |t|
    t.string "tracking_id", null: false
    t.datetime "submission_date"
    t.string "collection_key"
    t.string "language", default: "en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tracking_id"], name: "index_claims_on_tracking_id", unique: true
  end

  create_table "consents", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.json "driver_license"
    t.json "drug_test"
    t.json "biometric"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_consents_on_claim_id"
  end

  create_table "education_entries", force: :cascade do |t|
    t.integer "education_id", null: false
    t.string "institution"
    t.string "degree"
    t.string "field_of_study"
    t.date "start_date"
    t.date "end_date"
    t.boolean "is_current", default: false
    t.text "description"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["education_id"], name: "index_education_entries_on_education_id"
  end

  create_table "educations", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.string "highest_level"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_educations_on_claim_id"
  end

  create_table "employment_entries", force: :cascade do |t|
    t.integer "employment_history_id", null: false
    t.string "type"
    t.string "company"
    t.string "position"
    t.string "country"
    t.string "city"
    t.string "state_province"
    t.text "description"
    t.string "contact_name"
    t.string "contact_type"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "contact_preferred_method"
    t.boolean "no_contact_attestation", default: false
    t.text "contact_explanation"
    t.date "start_date"
    t.date "end_date"
    t.boolean "is_current", default: false
    t.float "duration_years", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employment_history_id"], name: "index_employment_entries_on_employment_history_id"
  end

  create_table "employment_histories", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.float "total_years", default: 0.0
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_employment_histories_on_claim_id"
  end

  create_table "form_submissions", force: :cascade do |t|
    t.string "current_step_id"
    t.json "steps", default: {}
    t.integer "user_id"
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "requirements_config_id"
    t.index ["requirements_config_id"], name: "index_form_submissions_on_requirements_config_id"
    t.index ["session_id"], name: "index_form_submissions_on_session_id"
    t.index ["user_id"], name: "index_form_submissions_on_user_id"
  end

  create_table "professional_license_entries", force: :cascade do |t|
    t.integer "professional_licenses_id", null: false
    t.string "license_type"
    t.string "license_number"
    t.string "issuing_authority"
    t.date "issue_date"
    t.date "expiration_date"
    t.boolean "is_active", default: true
    t.string "state"
    t.string "country"
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.boolean "is_current", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_licenses_id"], name: "index_professional_license_entries_on_professional_licenses_id"
  end

  create_table "professional_licenses", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_professional_licenses_on_claim_id"
  end

  create_table "requirements", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.json "consents_required", default: {}
    t.json "verification_steps", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_requirements_on_claim_id"
  end

  create_table "requirements_configs", force: :cascade do |t|
    t.json "consents_required", default: {"driver_license" => false, "drug_test" => false, "biometric" => false}
    t.json "verification_steps", default: {"personalInfo" => {"enabled" => true}, "residenceHistory" => {"enabled" => false, "years" => 3}, "employmentHistory" => {"enabled" => false}, "education" => {"enabled" => false}, "professionalLicense" => {"enabled" => false}}
    t.json "signature", default: {"required" => true, "mode" => "standard"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "residence_entries", force: :cascade do |t|
    t.integer "residence_history_id", null: false
    t.string "country"
    t.string "address"
    t.string "city"
    t.string "state_province"
    t.string "zip_postal"
    t.date "start_date"
    t.date "end_date"
    t.boolean "is_current", default: false
    t.float "duration_years", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["residence_history_id"], name: "index_residence_entries_on_residence_history_id"
  end

  create_table "residence_histories", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.float "total_years", default: 0.0
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_residence_histories_on_claim_id"
  end

  create_table "signatures", force: :cascade do |t|
    t.integer "claim_id", null: false
    t.text "data"
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_signatures_on_claim_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "claimants", "claims"
  add_foreign_key "consents", "claims"
  add_foreign_key "education_entries", "educations"
  add_foreign_key "educations", "claims"
  add_foreign_key "employment_entries", "employment_histories"
  add_foreign_key "employment_histories", "claims"
  add_foreign_key "form_submissions", "requirements_configs"
  add_foreign_key "form_submissions", "users"
  add_foreign_key "professional_license_entries", "professional_licenses", column: "professional_licenses_id"
  add_foreign_key "professional_licenses", "claims"
  add_foreign_key "requirements", "claims"
  add_foreign_key "residence_entries", "residence_histories"
  add_foreign_key "residence_histories", "claims"
  add_foreign_key "signatures", "claims"
end

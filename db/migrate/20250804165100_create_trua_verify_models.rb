class CreateTruaVerifyModels < ActiveRecord::Migration[8.0]
  def change
    # Create claims table
    create_table :claims do |t|
      t.string :tracking_id, null: false, index: { unique: true }
      t.datetime :submission_date
      t.string :collection_key
      t.string :language, default: 'en'

      t.timestamps
    end

    # Create claimants table
    create_table :claimants do |t|
      t.references :claim, null: false, foreign_key: true
      t.string :full_name
      t.string :email
      t.string :phone
      t.date :date_of_birth
      t.string :ssn
      t.datetime :completed_at

      t.timestamps
    end

    # Create requirements table
    create_table :requirements do |t|
      t.references :claim, null: false, foreign_key: true
      t.json :consents_required, default: {}
      t.json :verification_steps, default: {}

      t.timestamps
    end

    # Create consents table
    create_table :consents do |t|
      t.references :claim, null: false, foreign_key: true
      t.json :driver_license
      t.json :drug_test
      t.json :biometric
      t.datetime :completed_at

      t.timestamps
    end

    # Create residence_histories table
    create_table :residence_histories do |t|
      t.references :claim, null: false, foreign_key: true
      t.float :total_years, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    # Create residence_entries table
    create_table :residence_entries do |t|
      t.references :residence_history, null: false, foreign_key: true
      t.string :country
      t.string :address
      t.string :city
      t.string :state_province
      t.string :zip_postal
      t.date :start_date
      t.date :end_date
      t.boolean :is_current, default: false
      t.float :duration_years, default: 0

      t.timestamps
    end

    # Create employment_histories table
    create_table :employment_histories do |t|
      t.references :claim, null: false, foreign_key: true
      t.float :total_years, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    # Create employment_entries table
    create_table :employment_entries do |t|
      t.references :employment_history, null: false, foreign_key: true
      t.string :type
      t.string :company
      t.string :position
      t.string :country
      t.string :city
      t.string :state_province
      t.text :description
      t.string :contact_name
      t.string :contact_type
      t.string :contact_email
      t.string :contact_phone
      t.string :contact_preferred_method
      t.boolean :no_contact_attestation, default: false
      t.text :contact_explanation
      t.date :start_date
      t.date :end_date
      t.boolean :is_current, default: false
      t.float :duration_years, default: 0

      t.timestamps
    end

    # Create educations table
    create_table :educations do |t|
      t.references :claim, null: false, foreign_key: true
      t.string :highest_level
      t.datetime :completed_at

      t.timestamps
    end

    # Create education_entries table
    create_table :education_entries do |t|
      t.references :education, null: false, foreign_key: true
      t.string :institution
      t.string :degree
      t.string :field_of_study
      t.date :start_date
      t.date :end_date
      t.boolean :is_current, default: false
      t.text :description
      t.string :location

      t.timestamps
    end

    # Create professional_licenses table
    create_table :professional_licenses do |t|
      t.references :claim, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end

    # Create professional_license_entries table
    create_table :professional_license_entries do |t|
      t.references :professional_licenses, null: false, foreign_key: true
      t.string :license_type
      t.string :license_number
      t.string :issuing_authority
      t.date :issue_date
      t.date :expiration_date
      t.boolean :is_active, default: true
      t.string :state
      t.string :country
      t.text :description
      t.date :start_date
      t.date :end_date
      t.boolean :is_current, default: false

      t.timestamps
    end

    # Create signatures table
    create_table :signatures do |t|
      t.references :claim, null: false, foreign_key: true
      t.text :data
      t.datetime :date

      t.timestamps
    end
  end
end
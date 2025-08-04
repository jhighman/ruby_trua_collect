FactoryBot.define do
  factory :claim do
    tracking_id { "TV-#{SecureRandom.hex(6).upcase}" }
    submission_date { Time.current }
    collection_key { "en-EPA-DTB-R3-E3-E-P-W" }
    language { "en" }

    factory :claim_with_all_data do
      after(:create) do |claim|
        create(:claimant, claim: claim)
        create(:consents, claim: claim)
        
        residence_history = create(:residence_history, claim: claim)
        create_list(:residence_entry, 2, residence_history: residence_history)
        
        employment_history = create(:employment_history, claim: claim)
        create_list(:employment_entry, 2, employment_history: employment_history)
        
        education = create(:education, claim: claim)
        create_list(:education_entry, 1, education: education)
        
        professional_licenses = create(:professional_licenses, claim: claim)
        create_list(:professional_license_entry, 1, professional_licenses: professional_licenses)
        
        create(:signature, claim: claim)
      end
    end
  end

  factory :claimant do
    claim
    full_name { "John Doe" }
    email { "john.doe@example.com" }
    phone { "555-123-4567" }
    date_of_birth { 30.years.ago.to_date }
    ssn { "123-45-6789" }
    completed_at { Time.current }
  end

  factory :consents do
    claim
    driver_license { { "granted" => true, "date" => Time.current.iso8601, "notes" => nil } }
    drug_test { { "granted" => true, "date" => Time.current.iso8601, "notes" => nil } }
    biometric { { "granted" => true, "date" => Time.current.iso8601, "notes" => nil } }
    completed_at { Time.current }
  end

  factory :residence_history do
    claim
    total_years { 5.0 }
    completed_at { Time.current }
  end

  factory :residence_entry do
    residence_history
    country { "US" }
    address { "123 Main St" }
    city { "Anytown" }
    state_province { "CA" }
    zip_postal { "12345" }
    start_date { 3.years.ago.to_date }
    end_date { 1.year.ago.to_date }
    is_current { false }
    duration_years { 2.0 }

    trait :current do
      start_date { 1.year.ago.to_date }
      end_date { nil }
      is_current { true }
      duration_years { 1.0 }
    end
  end

  factory :employment_history do
    claim
    total_years { 5.0 }
    completed_at { Time.current }
  end

  factory :employment_entry do
    employment_history
    company { "Acme Inc." }
    position { "Software Engineer" }
    country { "US" }
    city { "Anytown" }
    state_province { "CA" }
    description { "Developed web applications" }
    contact_name { "Jane Smith" }
    contact_type { "Manager" }
    contact_email { "jane.smith@example.com" }
    contact_phone { "555-987-6543" }
    contact_preferred_method { "Email" }
    no_contact_attestation { false }
    contact_explanation { nil }
    start_date { 3.years.ago.to_date }
    end_date { 1.year.ago.to_date }
    is_current { false }
    duration_years { 2.0 }

    trait :current do
      start_date { 1.year.ago.to_date }
      end_date { nil }
      is_current { true }
      duration_years { 1.0 }
    end

    trait :no_contact do
      contact_name { nil }
      contact_type { nil }
      contact_email { nil }
      contact_phone { nil }
      contact_preferred_method { nil }
      no_contact_attestation { true }
      contact_explanation { "Company no longer exists" }
    end
  end

  factory :education do
    claim
    highest_level { "Bachelor's Degree" }
    completed_at { Time.current }
  end

  factory :education_entry do
    education
    institution { "University of Example" }
    degree { "Bachelor of Science" }
    field_of_study { "Computer Science" }
    start_date { 6.years.ago.to_date }
    end_date { 2.years.ago.to_date }
    is_current { false }
    description { "Studied computer science and software engineering" }
    location { "Anytown, CA" }

    trait :current do
      start_date { 2.years.ago.to_date }
      end_date { nil }
      is_current { true }
    end
  end

  factory :professional_licenses do
    claim
    completed_at { Time.current }
  end

  factory :professional_license_entry do
    professional_licenses
    license_type { "Professional Engineer" }
    license_number { "PE12345" }
    issuing_authority { "State Board of Engineering" }
    issue_date { 2.years.ago.to_date }
    expiration_date { 3.years.from_now.to_date }
    is_active { true }
    state { "CA" }
    country { "US" }
    description { "Professional engineering license" }
    start_date { 2.years.ago.to_date }
    end_date { 3.years.from_now.to_date }
    is_current { true }

    trait :expired do
      expiration_date { 1.year.ago.to_date }
      is_active { false }
      is_current { false }
      end_date { 1.year.ago.to_date }
    end
  end

  factory :signature do
    claim
    data { "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAApgAAAKYB3X3/OAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAANCSURBVEiJtZZPbBtFFMZ/M7ubXdtdb1xSFyeilBapySVU8h8OoFaooFSqiihIVIpQBKci6KEg9Q6H9kovIHoCIVQJJCKE1ENFjnAgcaSGC6rEnxBwA04Tx43t2FnvDAfjkNibxgHxnWb2e/u992bee7tCa00YFsffekFY+nUzFtjW0LrvjRXrCDIAaPLlW0nHL0SsZtVoaF98mLrx3pdhOqLtYPHChahZcYYO7KvPFxvRl5XPp1sN3adWiD1ZAqD6XYK1b/dvE5IWryTt2udLFedwc1+9kLp+vbbpoDh+6TklxBeAi9TL0taeWpdmZzQDry0AcO+jQ12RyohqqoYoo8RDwJrU+qXkjWtfi8Xxt58BdQuwQs9qC/afLwCw8tnQbqYAPsgxE1S6F3EAIXux2oQFKm0ihMsOF71dHYx+f3NND68ghCu1YIoePPQN1pGRABkJ6Bus96CutRZMydTl+TvuiRW1m3n0eDl0vRPcEysqdXn+jsQPsrHMquGeXEaY4Yk4wxWcY5V/9scqOMOVUFthatyTy8QyqwZ+kDURKoMWxNKr2EeqVKcTNOajqKoBgOE28U4tdQl5p5bwCw7BWquaZSzAPlwjlithJtp3pTImSqQRrb2Z8PHGigD4RZuNX6JYj6wj7O4TFLbCO/Mn/m8R+h6rYSUb3ekokRY6f/YukArN979jcW+V/S8g0eT/N3VN3kTqWbQ428m9/8k0P/1aIhF36PccEl6EhOcAUCrXKZXXWS3XKd2vc/TRBG9O5ELC17MmWubD2nKhUKZa26Ba2+D3P+4/MNCFwg59oWVeYhkzgN/JDR8deKBoD7Y+ljEjGZ0sos" }
    date { Time.current }
  end
end
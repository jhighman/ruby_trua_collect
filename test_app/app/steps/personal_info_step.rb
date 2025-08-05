# frozen_string_literal: true

class PersonalInfoStep < FormWizard::Step
  step_name :personal_info
  title 'Personal Information'
  description 'Please provide your personal information.'
  
  field :first_name, type: :text, required: true, label: 'First Name'
  field :last_name, type: :text, required: true, label: 'Last Name'
  field :date_of_birth, type: :date, required: false, label: 'Date of Birth'
  
  validate :validate_age
  
  private
  
  def validate_age(form_submission, params)
    return unless params['date_of_birth'].present?
    
    begin
      date_of_birth = Date.parse(params['date_of_birth'])
      age = ((Date.today - date_of_birth) / 365.25).to_i
      
      if age < 18
        add_error(:date_of_birth, 'You must be at least 18 years old')
      end
    rescue ArgumentError
      add_error(:date_of_birth, 'Invalid date format')
    end
  end
end
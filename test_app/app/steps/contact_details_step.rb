# frozen_string_literal: true

class ContactDetailsStep < FormWizard::Step
  step_name :contact_details
  title 'Contact Details'
  description 'Please provide your contact information.'
  
  field :email, type: :text, required: true, label: 'Email Address'
  field :phone, type: :text, required: false, label: 'Phone Number'
  field :preferred_contact, type: :select, required: true, label: 'Preferred Contact Method',
        options: [['Email', 'email'], ['Phone', 'phone']], prompt: 'Select a contact method'
  
  validate :validate_email
  validate :validate_phone
  validate :validate_preferred_contact
  
  private
  
  def validate_email(form_submission, params)
    return unless params['email'].present?
    
    unless params['email'] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      add_error(:email, 'Invalid email format')
    end
  end
  
  def validate_phone(form_submission, params)
    return unless params['phone'].present?
    
    unless params['phone'] =~ /\A[\d\+\-\(\) ]{7,}\z/
      add_error(:phone, 'Invalid phone number format')
    end
  end
  
  def validate_preferred_contact(form_submission, params)
    if params['preferred_contact'] == 'phone' && params['phone'].blank?
      add_error(:preferred_contact, 'Phone number is required when phone is the preferred contact method')
    end
  end
end
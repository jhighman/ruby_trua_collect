# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Form Validation', type: :feature do
  let(:session_id) { SecureRandom.uuid }
  let(:form_submission) { FormSubmission.create(session_id: session_id) }
  let(:flow) { ContactFormFlow.new }
  
  describe 'ValidationService' do
    it 'validates a step' do
      # Create a validation service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Test with valid params
      result = service.validate_step(
        step: 'personal_info',
        params: {
          'first_name' => 'John',
          'last_name' => 'Doe'
        },
        flow: flow
      )
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
      
      # Test with invalid params
      result = service.validate_step(
        step: 'personal_info',
        params: {
          'first_name' => '',
          'last_name' => ''
        },
        flow: flow
      )
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).not_to be_empty
    end
    
    it 'validates the entire form' do
      # Create a validation service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Set up form_submission with valid data
      form_submission.set_field_value('first_name', 'John')
      form_submission.set_field_value('last_name', 'Doe')
      form_submission.set_field_value('email', 'john.doe@example.com')
      form_submission.set_field_value('preferred_contact', 'email')
      form_submission.set_field_value('terms_accepted', '1')
      
      # Validate the entire form
      result = service.validate_form(flow: flow)
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
      
      # Set up form_submission with invalid data
      form_submission.set_field_value('email', 'invalid-email')
      
      # Validate the entire form
      result = service.validate_form(flow: flow)
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).not_to be_empty
    end
  end
  
  describe 'Step Validations' do
    describe 'PersonalInfoStep' do
      it 'validates required fields' do
        step = FormWizard.find_step('personal_info')
        
        # Test with empty params
        valid = step.validate(form_submission, {})
        
        # Should fail validation
        expect(valid).to be false
        expect(step.errors).to include(/first_name.*required/)
        expect(step.errors).to include(/last_name.*required/)
        
        # Test with valid params
        valid = step.validate(form_submission, {
          'first_name' => 'John',
          'last_name' => 'Doe'
        })
        
        # Should pass validation
        expect(valid).to be true
        expect(step.errors).to be_empty
      end
      
      it 'validates date of birth' do
        step = FormWizard.find_step('personal_info')
        
        # Test with underage date of birth
        valid = step.validate(form_submission, {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'date_of_birth' => (Date.today - 17.years).to_s
        })
        
        # Should fail validation
        expect(valid).to be false
        expect(step.errors).to include(/date_of_birth.*18 years old/)
        
        # Test with valid date of birth
        valid = step.validate(form_submission, {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'date_of_birth' => (Date.today - 20.years).to_s
        })
        
        # Should pass validation
        expect(valid).to be true
        expect(step.errors).to be_empty
      end
    end
    
    describe 'ContactDetailsStep' do
      it 'validates email format' do
        step = FormWizard.find_step('contact_details')
        
        # Test with invalid email
        valid = step.validate(form_submission, {
          'email' => 'invalid-email',
          'preferred_contact' => 'email'
        })
        
        # Should fail validation
        expect(valid).to be false
        expect(step.errors).to include(/email.*invalid/i)
        
        # Test with valid email
        valid = step.validate(form_submission, {
          'email' => 'john.doe@example.com',
          'preferred_contact' => 'email'
        })
        
        # Should pass validation
        expect(valid).to be true
        expect(step.errors).to be_empty
      end
      
      it 'validates phone when preferred contact is phone' do
        step = FormWizard.find_step('contact_details')
        
        # Test with missing phone
        valid = step.validate(form_submission, {
          'email' => 'john.doe@example.com',
          'preferred_contact' => 'phone'
        })
        
        # Should fail validation
        expect(valid).to be false
        expect(step.errors).to include(/phone.*required/i)
        
        # Test with invalid phone
        valid = step.validate(form_submission, {
          'email' => 'john.doe@example.com',
          'phone' => 'abc',
          'preferred_contact' => 'phone'
        })
        
        # Should fail validation
        expect(valid).to be false
        expect(step.errors).to include(/phone.*invalid/i)
        
        # Test with valid phone
        valid = step.validate(form_submission, {
          'email' => 'john.doe@example.com',
          'phone' => '+1 (555) 555-5555',
          'preferred_contact' => 'phone'
        })
        
        # Should pass validation
        expect(valid).to be true
        expect(step.errors).to be_empty
      end
    end
    
    describe 'ReviewStep' do
      it 'validates terms acceptance' do
        step = FormWizard.find_step('review')
        
        # Test without accepting terms
        valid = step.validate(form_submission, {})
        
        # Should fail validation
        expect(valid).to be false
        expect(step.errors).to include(/terms_accepted.*confirm/i)
        
        # Test with accepting terms
        valid = step.validate(form_submission, {
          'terms_accepted' => '1'
        })
        
        # Should pass validation
        expect(valid).to be true
        expect(step.errors).to be_empty
      end
    end
  end
end
# frozen_string_literal: true

# This script tests the form submission process
# It simulates a user filling out the form and submitting it

require 'rails_helper'

RSpec.describe 'Form Submission', type: :feature do
  let(:session_id) { SecureRandom.uuid }
  let(:form_submission) { FormSubmission.create(session_id: session_id) }
  
  describe 'Personal Info Step' do
    it 'validates required fields' do
      # Create a form submission service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Test with empty params
      result = service.validate_step(
        step: 'personal_info',
        params: {},
        flow: ContactFormFlow.new
      )
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).to include(/first_name.*required/)
      expect(result.errors).to include(/last_name.*required/)
      
      # Test with valid params
      result = service.validate_step(
        step: 'personal_info',
        params: {
          'first_name' => 'John',
          'last_name' => 'Doe'
        },
        flow: ContactFormFlow.new
      )
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
    end
    
    it 'validates age' do
      # Create a form submission service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Test with underage date of birth
      result = service.validate_step(
        step: 'personal_info',
        params: {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'date_of_birth' => (Date.today - 17.years).to_s
        },
        flow: ContactFormFlow.new
      )
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).to include(/date_of_birth.*18 years old/)
      
      # Test with valid date of birth
      result = service.validate_step(
        step: 'personal_info',
        params: {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'date_of_birth' => (Date.today - 20.years).to_s
        },
        flow: ContactFormFlow.new
      )
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
    end
  end
  
  describe 'Contact Details Step' do
    it 'validates email format' do
      # Create a form submission service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Test with invalid email
      result = service.validate_step(
        step: 'contact_details',
        params: {
          'email' => 'invalid-email',
          'preferred_contact' => 'email'
        },
        flow: ContactFormFlow.new
      )
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).to include(/email.*invalid/i)
      
      # Test with valid email
      result = service.validate_step(
        step: 'contact_details',
        params: {
          'email' => 'john.doe@example.com',
          'preferred_contact' => 'email'
        },
        flow: ContactFormFlow.new
      )
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
    end
    
    it 'validates phone when preferred contact is phone' do
      # Create a form submission service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Test with missing phone
      result = service.validate_step(
        step: 'contact_details',
        params: {
          'email' => 'john.doe@example.com',
          'preferred_contact' => 'phone'
        },
        flow: ContactFormFlow.new
      )
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).to include(/phone.*required/i)
      
      # Test with valid phone
      result = service.validate_step(
        step: 'contact_details',
        params: {
          'email' => 'john.doe@example.com',
          'phone' => '+1 (555) 555-5555',
          'preferred_contact' => 'phone'
        },
        flow: ContactFormFlow.new
      )
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
    end
  end
  
  describe 'Review Step' do
    it 'validates terms acceptance' do
      # Create a form submission service
      service = FormWizard::ValidationService.new(form_submission)
      
      # Test without accepting terms
      result = service.validate_step(
        step: 'review',
        params: {},
        flow: ContactFormFlow.new
      )
      
      # Should fail validation
      expect(result.valid?).to be false
      expect(result.errors).to include(/terms_accepted.*confirm/i)
      
      # Test with accepting terms
      result = service.validate_step(
        step: 'review',
        params: {
          'terms_accepted' => '1'
        },
        flow: ContactFormFlow.new
      )
      
      # Should pass validation
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
    end
  end
  
  describe 'Form Submission Process' do
    it 'processes a complete form submission' do
      # Create a form submission service
      service = FormWizard::FormSubmissionService.new(form_submission)
      
      # Process personal info step
      result = service.process_step(
        step: 'personal_info',
        params: {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'date_of_birth' => (Date.today - 20.years).to_s
        },
        flow: ContactFormFlow.new
      )
      
      # Should succeed and move to next step
      expect(result.success?).to be true
      expect(result.next_step).to eq('contact_details')
      expect(form_submission.step_completed?('personal_info')).to be true
      
      # Process contact details step
      result = service.process_step(
        step: 'contact_details',
        params: {
          'email' => 'john.doe@example.com',
          'phone' => '+1 (555) 555-5555',
          'preferred_contact' => 'email'
        },
        flow: ContactFormFlow.new
      )
      
      # Should succeed and move to next step
      expect(result.success?).to be true
      expect(result.next_step).to eq('review')
      expect(form_submission.step_completed?('contact_details')).to be true
      
      # Process review step
      result = service.process_step(
        step: 'review',
        params: {
          'terms_accepted' => '1'
        },
        flow: ContactFormFlow.new
      )
      
      # Should succeed and complete the form
      expect(result.success?).to be true
      expect(result.next_step).to be_nil
      expect(form_submission.step_completed?('review')).to be true
      expect(form_submission.completed).to be true
    end
  end
end
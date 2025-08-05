# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Form Navigation', type: :feature do
  let(:session_id) { SecureRandom.uuid }
  let(:form_submission) { FormSubmission.create(session_id: session_id) }
  let(:flow) { ContactFormFlow.new }
  
  describe 'Navigation Service' do
    it 'returns the correct next step' do
      # Create a navigation service
      service = FormWizard::NavigationService.new(form_submission)
      
      # Test next step from personal_info
      next_step = service.next_step(current_step: 'personal_info', flow: flow)
      expect(next_step).to eq('contact_details')
      
      # Test next step from contact_details
      next_step = service.next_step(current_step: 'contact_details', flow: flow)
      expect(next_step).to eq('review')
      
      # Test next step from review (should be nil as it's the last step)
      next_step = service.next_step(current_step: 'review', flow: flow)
      expect(next_step).to be_nil
    end
    
    it 'returns the correct previous step' do
      # Create a navigation service
      service = FormWizard::NavigationService.new(form_submission)
      
      # Test previous step from contact_details
      previous_step = service.previous_step(current_step: 'contact_details', flow: flow)
      expect(previous_step).to eq('personal_info')
      
      # Test previous step from review
      previous_step = service.previous_step(current_step: 'review', flow: flow)
      expect(previous_step).to eq('contact_details')
      
      # Test previous step from personal_info (should be nil as it's the first step)
      previous_step = service.previous_step(current_step: 'personal_info', flow: flow)
      expect(previous_step).to be_nil
    end
    
    it 'handles conditional navigation' do
      # Create a navigation service
      service = FormWizard::NavigationService.new(form_submission)
      
      # Set up form_submission to trigger conditional navigation
      form_submission.set_field_value('first_name', '')
      form_submission.set_field_value('last_name', '')
      
      # Test next step from personal_info with conditional navigation
      next_step = service.next_step(current_step: 'personal_info', flow: flow)
      expect(next_step).to eq('review')
      
      # Reset form_submission to not trigger conditional navigation
      form_submission.set_field_value('first_name', 'John')
      form_submission.set_field_value('last_name', 'Doe')
      
      # Test next step from personal_info without conditional navigation
      next_step = service.next_step(current_step: 'personal_info', flow: flow)
      expect(next_step).to eq('contact_details')
    end
    
    it 'checks if navigation to a step is allowed' do
      # Create a navigation service
      service = FormWizard::NavigationService.new(form_submission)
      
      # Mark personal_info as completed
      form_submission.mark_step_completed('personal_info')
      
      # Should be able to navigate to personal_info (completed step)
      expect(service.can_navigate_to?(step: 'personal_info', flow: flow)).to be true
      
      # Should be able to navigate to contact_details (next step)
      expect(service.can_navigate_to?(step: 'contact_details', flow: flow)).to be true
      
      # Should not be able to navigate to review (not next step and not completed)
      expect(service.can_navigate_to?(step: 'review', flow: flow)).to be false
      
      # Mark contact_details as completed
      form_submission.mark_step_completed('contact_details')
      
      # Should be able to navigate to review (next step)
      expect(service.can_navigate_to?(step: 'review', flow: flow)).to be true
    end
  end
  
  describe 'Flow Navigation' do
    it 'follows the defined flow' do
      # Create a form submission service
      service = FormWizard::FormSubmissionService.new(form_submission)
      
      # Process personal info step
      result = service.process_step(
        step: 'personal_info',
        params: {
          'first_name' => 'John',
          'last_name' => 'Doe'
        },
        flow: flow
      )
      
      # Should move to contact_details
      expect(result.next_step).to eq('contact_details')
      
      # Process contact details step
      result = service.process_step(
        step: 'contact_details',
        params: {
          'email' => 'john.doe@example.com',
          'preferred_contact' => 'email'
        },
        flow: flow
      )
      
      # Should move to review
      expect(result.next_step).to eq('review')
      
      # Process review step
      result = service.process_step(
        step: 'review',
        params: {
          'terms_accepted' => '1'
        },
        flow: flow
      )
      
      # Should complete the form
      expect(result.next_step).to be_nil
      expect(form_submission.completed).to be true
    end
    
    it 'follows conditional navigation rules' do
      # Create a form submission service
      service = FormWizard::FormSubmissionService.new(form_submission)
      
      # Process personal info step with empty name to trigger conditional navigation
      result = service.process_step(
        step: 'personal_info',
        params: {
          'first_name' => '',
          'last_name' => ''
        },
        flow: flow
      )
      
      # Should skip contact_details and go to review
      expect(result.next_step).to eq('review')
    end
  end
end
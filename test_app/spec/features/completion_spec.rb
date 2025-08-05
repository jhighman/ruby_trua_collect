# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Form Completion', type: :feature do
  let(:session_id) { SecureRandom.uuid }
  let(:form_submission) { FormSubmission.create(session_id: session_id) }
  let(:flow) { ContactFormFlow.new }
  
  describe 'Form Completion' do
    it 'marks the form as completed' do
      # Create a form submission service
      service = FormWizard::FormSubmissionService.new(form_submission)
      
      # Complete all steps
      form_submission.mark_step_completed('personal_info')
      form_submission.mark_step_completed('contact_details')
      
      # Process the final step
      result = service.process_step(
        step: 'review',
        params: {
          'terms_accepted' => '1'
        },
        flow: flow
      )
      
      # Should complete the form
      expect(result.success?).to be true
      expect(result.next_step).to be_nil
      expect(form_submission.completed).to be true
    end
    
    it 'triggers completion events' do
      # Set up event tracking
      completion_triggered = false
      
      # Subscribe to the form_completed event
      FormWizard.on(:form_completed) do |form|
        completion_triggered = true
      end
      
      # Create a form submission service
      service = FormWizard::FormSubmissionService.new(form_submission)
      
      # Complete all steps
      form_submission.mark_step_completed('personal_info')
      form_submission.mark_step_completed('contact_details')
      
      # Process the final step
      result = service.process_step(
        step: 'review',
        params: {
          'terms_accepted' => '1'
        },
        flow: flow
      )
      
      # Should trigger the completion event
      expect(completion_triggered).to be true
    end
  end
  
  describe 'Flow Completion Rules' do
    it 'completes the form based on completion rules' do
      # Create a flow with a completion rule
      class TestFlow < FormWizard::Flow
        flow_name :test_flow
        
        step :step_one
        step :step_two
        step :step_three
        
        complete_if ->(form_submission) { form_submission.get_field_value('skip_remaining') == 'yes' }, after: :step_one
      end
      
      # Create a form submission service
      service = FormWizard::FormSubmissionService.new(form_submission)
      
      # Set the skip_remaining field to 'yes'
      form_submission.set_field_value('skip_remaining', 'yes')
      
      # Process step_one
      result = service.process_step(
        step: 'step_one',
        params: {},
        flow: TestFlow.new
      )
      
      # Should complete the form based on the completion rule
      expect(result.success?).to be true
      expect(result.next_step).to be_nil
      expect(form_submission.completed).to be true
    end
  end
  
  describe 'Progress Tracking' do
    it 'tracks progress correctly' do
      # Initially progress should be 0%
      expect(form_submission.progress_percentage(flow)).to eq(0)
      
      # Complete the first step
      form_submission.mark_step_completed('personal_info')
      
      # Progress should be 33% (1/3 steps)
      expect(form_submission.progress_percentage(flow)).to eq(33)
      
      # Complete the second step
      form_submission.mark_step_completed('contact_details')
      
      # Progress should be 67% (2/3 steps)
      expect(form_submission.progress_percentage(flow)).to eq(67)
      
      # Complete the third step
      form_submission.mark_step_completed('review')
      
      # Progress should be 100% (3/3 steps)
      expect(form_submission.progress_percentage(flow)).to eq(100)
    end
    
    it 'returns 100% for completed forms' do
      # Mark the form as completed
      form_submission.complete!
      
      # Progress should be 100%
      expect(form_submission.progress_percentage(flow)).to eq(100)
    end
  end
  
  describe 'Form Data' do
    it 'stores and retrieves form data correctly' do
      # Set field values
      form_submission.set_field_value('first_name', 'John')
      form_submission.set_field_value('last_name', 'Doe')
      form_submission.set_field_value('email', 'john.doe@example.com')
      
      # Get field values
      expect(form_submission.get_field_value('first_name')).to eq('John')
      expect(form_submission.get_field_value('last_name')).to eq('Doe')
      expect(form_submission.get_field_value('email')).to eq('john.doe@example.com')
      
      # Get step values
      step_values = form_submission.get_step_values('personal_info')
      expect(step_values['first_name']).to eq('John')
      expect(step_values['last_name']).to eq('Doe')
    end
    
    it 'clears field values' do
      # Set field values
      form_submission.set_field_value('first_name', 'John')
      form_submission.set_field_value('last_name', 'Doe')
      
      # Clear a field value
      form_submission.clear_field_value('first_name')
      
      # The field should be cleared
      expect(form_submission.get_field_value('first_name')).to be_nil
      expect(form_submission.get_field_value('last_name')).to eq('Doe')
      
      # Clear all field values
      form_submission.clear_all_field_values
      
      # All fields should be cleared
      expect(form_submission.get_field_value('last_name')).to be_nil
    end
  end
end
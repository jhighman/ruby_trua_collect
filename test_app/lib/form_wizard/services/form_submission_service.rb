# frozen_string_literal: true

module FormWizard
  class FormSubmissionService < BaseService
    def process_step(step:, params:, flow:)
      step_instance = FormWizard.find_step(step)
      return Result.new(success: false, errors: ['Step not found']) unless step_instance
      
      validation_service = ValidationService.new(form_submission)
      validation_result = validation_service.validate_step(step: step, params: params, flow: flow)
      
      return Result.new(success: false, errors: validation_result.errors) unless validation_result.valid?
      
      # Save form data
      save_form_data(params)
      
      # Mark step as completed
      form_submission.mark_step_completed(step.to_s)
      
      # Trigger step complete event
      flow.trigger_step_complete(step, form_submission)
      FormWizard.trigger(:step_completed, form_submission, step)
      
      # Check if form should be completed
      if flow.should_complete?(form_submission, step)
        complete_form(flow)
        return Result.new(success: true, next_step: nil)
      end
      
      # Get next step
      navigation_service = NavigationService.new(form_submission)
      next_step = navigation_service.next_step(current_step: step, flow: flow)
      
      Result.new(success: true, next_step: next_step)
    end
    
    def complete_form(flow)
      form_submission.complete!
      
      # Trigger complete events
      flow.trigger_complete(form_submission)
      FormWizard.trigger(:form_completed, form_submission)
    end
    
    private
    
    def save_form_data(params)
      return unless params.is_a?(Hash) || params.is_a?(ActionController::Parameters)
      
      data = params.to_h.deep_symbolize_keys
      form_submission.set_field_values(data)
    end
  end
end
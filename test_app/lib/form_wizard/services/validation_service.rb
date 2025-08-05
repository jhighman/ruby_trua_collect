# frozen_string_literal: true

module FormWizard
  class ValidationService < BaseService
    def validate_step(step:, params:, flow:)
      step_instance = FormWizard.find_step(step)
      return Result.new(success: false, errors: ['Step not found']) unless step_instance
      
      # Validate step
      valid = step_instance.validate(form_submission, params)
      
      if valid
        Result.new(success: true)
      else
        Result.new(success: false, errors: step_instance.errors)
      end
    end
    
    def validate_form(flow:)
      errors = []
      
      # Validate all steps
      flow.steps.each do |step_name|
        step_instance = FormWizard.find_step(step_name)
        next unless step_instance
        
        # Get step data
        step_data = form_submission.get_step_values(step_name)
        
        # Validate step
        unless step_instance.validate(form_submission, step_data)
          errors.concat(step_instance.errors)
        end
      end
      
      if errors.empty?
        Result.new(success: true)
      else
        Result.new(success: false, errors: errors)
      end
    end
  end
end
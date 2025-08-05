# frozen_string_literal: true

module FormWizard
  # Service for form wizard validation
  class ValidationService < BaseService
    # Validate a step
    # @param step_id [Symbol, String] The step ID
    # @param values [Hash] The values to validate
    # @return [Hash] Validation result with :is_valid and :errors keys
    def validate_step(step_id, values)
      step_id = step_id.to_sym
      step = ::FormWizard.find_step(step_id)
      
      return { is_valid: false, errors: { base: 'Step not found' } } unless step
      
      # Use the step's validation method
      result = step.valid?(values, @form_submission)
      
      # Publish validation event
      publish(:step_validated, @form_submission, step_id, result)
      
      result
    end
    
    # Check if a step is complete
    # @param step_id [Symbol, String] The step ID
    # @param values [Hash] The values to check
    # @return [Boolean] Whether the step is complete
    def step_complete?(step_id, values)
      step_id = step_id.to_sym
      step = ::FormWizard.find_step(step_id)
      
      return false unless step
      
      # Use the step's completion method
      step.complete?(values, @form_submission)
    end
    
    # Update a step's state
    # @param step_id [Symbol, String] The step ID
    # @param values [Hash] The values to update
    # @return [Boolean] Whether the update was successful
    def update_step(step_id, values)
      step_id = step_id.to_sym
      
      # Validate the step
      validation_result = validate_step(step_id, values)
      
      # Check completion
      is_complete = step_complete?(step_id, values)
      
      # Update the step state
      result = @form_submission.update_step_state(step_id, {
        values: values,
        is_valid: validation_result[:is_valid],
        errors: validation_result[:errors],
        is_complete: is_complete
      })
      
      # Publish step updated event
      publish(:step_updated, @form_submission, step_id) if result
      
      # Publish step completed event if the step is now complete
      publish(:step_completed, @form_submission, step_id) if result && is_complete
      
      result
    end
    
    # Validate the entire form
    # @return [Hash] Validation result with :is_valid, :errors, and :incomplete_steps keys
    def validate_form
      errors = {}
      incomplete_steps = []
      
      available_steps.each do |step_id|
        # Get the step values
        values = @form_submission.step_values(step_id)
        
        # Validate the step
        result = validate_step(step_id, values)
        
        # Add errors if any
        errors[step_id] = result[:errors] unless result[:is_valid]
        
        # Check completion
        incomplete_steps << step_id unless step_complete?(step_id, values)
      end
      
      {
        is_valid: errors.empty?,
        errors: errors,
        incomplete_steps: incomplete_steps
      }
    end
  end
end
# frozen_string_literal: true

module FormWizard
  # Service for form wizard submission
  class FormSubmissionService < BaseService
    # Get a service instance
    # @param form_submission [FormSubmission] The form submission
    # @return [FormSubmissionService] The service instance
    def self.for(form_submission)
      new(form_submission)
    end
    
    # Initialize services
    def initialize(form_submission)
      super(form_submission)
      @navigation_service = NavigationService.new(form_submission)
      @validation_service = ValidationService.new(form_submission)
    end
    
    # Get the navigation service
    # @return [NavigationService] The navigation service
    def navigation
      @navigation_service
    end
    
    # Get the validation service
    # @return [ValidationService] The validation service
    def validation
      @validation_service
    end
    
    # Update a step
    # @param step_id [Symbol, String] The step ID
    # @param values [Hash] The values to update
    # @return [Boolean] Whether the update was successful
    def update_step(step_id, values)
      validation.update_step(step_id, values)
    end
    
    # Move to the next step
    # @return [Boolean] Whether the move was successful
    def next_step
      navigation.move_next
    end
    
    # Move to the previous step
    # @return [Boolean] Whether the move was successful
    def previous_step
      navigation.move_previous
    end
    
    # Move to a specific step
    # @param step_id [Symbol, String] The step ID
    # @return [Boolean] Whether the move was successful
    def move_to_step(step_id)
      navigation.move_to_step(step_id)
    end
    
    # Get the navigation state
    # @return [Hash] The navigation state
    def navigation_state
      navigation.navigation_state
    end
    
    # Submit the form
    # @return [Hash] Submission result with :success and :errors keys
    def submit
      # Validate the form
      validation_result = validation.validate_form
      
      unless validation_result[:is_valid]
        return { 
          success: false, 
          errors: validation_result[:errors],
          incomplete_steps: validation_result[:incomplete_steps]
        }
      end
      
      # Mark the form as submitted
      @form_submission.update(submitted_at: Time.current) if @form_submission.respond_to?(:submitted_at=)
      
      # Publish form submitted event
      publish(:form_submitted, @form_submission)
      
      { success: true }
    end
    
    # Reset the form
    # @return [Boolean] Whether the reset was successful
    def reset
      # Clear all step states
      @form_submission.steps = {}
      
      # Reset to the first step
      @form_submission.current_step_id = available_steps.first
      
      # Save the changes
      result = @form_submission.save
      
      # Publish form reset event
      publish(:form_reset, @form_submission) if result
      
      result
    end
  end
end
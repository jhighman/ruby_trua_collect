# frozen_string_literal: true

module FormWizard
  # Base class for form wizard components
  class BaseComponent < ViewComponent::Base
    # Initialize a new component
    # @param form_submission [FormSubmission] The form submission
    # @param step_id [Symbol, String] The step ID
    # @param options [Hash] Additional options
    def initialize(form_submission:, step_id: nil, **options)
      @form_submission = form_submission
      @step_id = step_id&.to_sym || form_submission.current_step_id&.to_sym
      @options = options
      @service = ::FormWizard::FormSubmissionService.new(form_submission)
    end
    
    # Get the form submission
    # @return [FormSubmission] The form submission
    attr_reader :form_submission
    
    # Get the step ID
    # @return [Symbol] The step ID
    attr_reader :step_id
    
    # Get the options
    # @return [Hash] The options
    attr_reader :options
    
    # Get the service
    # @return [FormSubmissionService] The service
    attr_reader :service
    
    # Get the current step
    # @return [Step] The current step
    def current_step
      ::FormWizard.find_step(step_id)
    end
    
    # Get the step values
    # @return [Hash] The step values
    def step_values
      form_submission.step_values(step_id) || {}
    end
    
    # Get the step errors
    # @return [Hash] The step errors
    def step_errors
      form_submission.step_errors(step_id) || {}
    end
    
    # Get the navigation state
    # @return [Hash] The navigation state
    def navigation_state
      service.navigation_state
    end
    
    # Check if the step is valid
    # @return [Boolean] Whether the step is valid
    def step_valid?
      form_submission.step_valid?(step_id)
    end
    
    # Check if the step is complete
    # @return [Boolean] Whether the step is complete
    def step_complete?
      form_submission.step_complete?(step_id)
    end
    
    # Get the progress percentage
    # @return [Integer] The progress percentage (0-100)
    def progress_percentage
      service.navigation.progress_percentage
    end
  end
end
# frozen_string_literal: true

module FormWizard
  # Base class for form wizard services
  class BaseService
    attr_reader :form_submission
    
    # Initialize a new service
    # @param form_submission [FormSubmission] The form submission
    def initialize(form_submission)
      @form_submission = form_submission
    end
    
    # Get the current step ID
    # @return [Symbol] The current step ID
    def current_step_id
      @form_submission.current_step_id&.to_sym
    end
    
    # Get the current step
    # @return [Step] The current step
    def current_step
      ::FormWizard.find_step(current_step_id)
    end
    
    # Get the flow for this form submission
    # @return [Flow] The flow
    def flow
      @flow ||= ::FormWizard::FlowRegistry.find_flow_for(@form_submission)
    end
    
    # Get the requirements for this form submission
    # @return [RequirementsConfig] The requirements
    def requirements
      @requirements ||= @form_submission.requirements_config
    end
    
    # Check if a step is enabled based on requirements
    # @param step_id [Symbol, String] The step ID
    # @return [Boolean] Whether the step is enabled
    def step_enabled?(step_id)
      return true unless requirements.respond_to?(:step_enabled?)
      
      requirements.step_enabled?(step_id.to_s)
    end
    
    # Get all available steps (enabled steps)
    # @return [Array<Symbol>] All available step IDs
    def available_steps
      ::FormWizard.step_ids.select { |step_id| step_enabled?(step_id) }
    end
    
    # Get all completed steps
    # @return [Array<Symbol>] All completed step IDs
    def completed_steps
      @form_submission.completed_steps.map(&:to_sym)
    end
    
    # Check if the form is complete
    # @return [Boolean] Whether the form is complete
    def complete?
      available_steps.all? { |step_id| @form_submission.step_complete?(step_id) }
    end
    
    # Publish an event
    # @param event [Symbol] The event to publish
    # @param args [Array] Arguments to pass to the event handlers
    def publish(event, *args)
      ::FormWizard.publish(event, *args)
    end
  end
end
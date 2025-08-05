# frozen_string_literal: true

module FormWizard
  # Registry for form wizard flows
  class FlowRegistry
    class << self
      # Get all registered flows
      # @return [Array<Flow>] All registered flows
      def flows
        @flows ||= []
      end

      # Register a new flow
      # @param flow [Flow] The flow to register
      # @return [Flow] The registered flow
      def register_flow(flow)
        # Remove any existing flow with the same name
        flows.reject! { |f| f.name == flow.name }
        
        # Add the new flow
        flows << flow
        
        # Publish flow registered event
        FormWizard.publish(:flow_registered, flow)
        
        flow
      end

      # Find a flow by name
      # @param name [Symbol, String] The flow name to find
      # @return [Flow, nil] The flow if found, nil otherwise
      def find_flow(name)
        flows.find { |flow| flow.name.to_s == name.to_s }
      end
      
      # Find a flow for a form submission
      # @param form_submission [FormSubmission] The form submission
      # @return [Flow] The flow for the form submission
      def find_flow_for(form_submission)
        # Try to find a flow based on the form submission's flow_name
        if form_submission.respond_to?(:flow_name) && form_submission.flow_name
          flow = find_flow(form_submission.flow_name)
          return flow if flow
        end
        
        # Fall back to the default flow
        find_flow(:default) || flows.first
      end
      
      # Clear all registered flows
      # Mainly used for testing
      def clear
        @flows = []
      end
    end
  end
end
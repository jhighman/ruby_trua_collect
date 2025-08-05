# frozen_string_literal: true

module FormWizard
  # Registry for form wizard steps
  class Registry
    class << self
      # Get all registered steps
      # @return [Array<Step>] All registered steps
      def steps
        @steps ||= []
      end

      # Register a new step
      # @param id [Symbol, String] The unique identifier for the step
      # @param options [Hash] Options for the step
      # @param block [Block] Configuration block for the step
      # @return [Step] The created step
      def register_step(id, options = {}, &block)
        step = Step.new(id, options)
        step.instance_eval(&block) if block_given?
        
        # Remove any existing step with the same ID
        steps.reject! { |s| s.id.to_s == id.to_s }
        
        # Add the new step
        steps << step
        
        # Sort steps by position
        steps.sort_by! { |s| s.position || Float::INFINITY }
        
        # Publish step registered event
        FormWizard.publish(:step_registered, step)
        
        step
      end

      # Find a step by ID
      # @param id [Symbol, String] The step ID to find
      # @return [Step, nil] The step if found, nil otherwise
      def find_step(id)
        steps.find { |step| step.id.to_s == id.to_s }
      end

      # Get all step IDs
      # @return [Array<Symbol>] All step IDs
      def step_ids
        steps.map(&:id)
      end
      
      # Clear all registered steps
      # Mainly used for testing
      def clear
        @steps = []
      end
    end
  end
end
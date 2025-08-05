# frozen_string_literal: true

# FormWizard is a framework for building multi-step form wizards
# with configurable steps, fields, and validation rules.
module FormWizard
  class << self
    # Define a new step in the registry
    # @param id [Symbol, String] The unique identifier for the step
    # @param options [Hash] Options for the step
    # @param block [Block] Configuration block for the step
    # @return [Step] The created step
    def define_step(id, options = {}, &block)
      Registry.register_step(id, options, &block)
    end
    
    # Find a step by ID
    # @param id [Symbol, String] The step ID to find
    # @return [Step, nil] The step if found, nil otherwise
    def find_step(id)
      Registry.find_step(id)
    end
    
    # Get all registered steps
    # @return [Array<Step>] All registered steps
    def steps
      Registry.steps
    end
    
    # Get all step IDs
    # @return [Array<Symbol>] All step IDs
    def step_ids
      Registry.step_ids
    end
    
    # Define a new flow
    # @param name [Symbol, String] The unique identifier for the flow
    # @param options [Hash] Options for the flow
    # @param block [Block] Configuration block for the flow
    # @return [Flow] The created flow
    def define_flow(name, options = {}, &block)
      flow = Flow.new(name, options)
      flow.instance_eval(&block) if block_given?
      FlowRegistry.register_flow(flow)
      flow
    end
    
    # Subscribe to an event
    # @param event [Symbol] The event to subscribe to
    # @param block [Block] The handler for the event
    def on(event, &block)
      EventManager.subscribe(event, &block)
    end
    
    # Publish an event
    # @param event [Symbol] The event to publish
    # @param args [Array] Arguments to pass to the event handlers
    def publish(event, *args)
      EventManager.publish(event, *args)
    end
  end
end

# Require all the framework files
require_relative 'form_wizard/registry'
require_relative 'form_wizard/step'
require_relative 'form_wizard/field'
require_relative 'form_wizard/event_manager'
require_relative 'form_wizard/flow'
require_relative 'form_wizard/flow_registry'
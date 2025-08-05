# frozen_string_literal: true

module FormWizard
  # Represents a flow in the form wizard
  class Flow
    attr_reader :name, :steps, :transitions, :options
    
    # Initialize a new flow
    # @param name [Symbol, String] The unique identifier for the flow
    # @param options [Hash] Options for the flow
    def initialize(name, options = {})
      @name = name.to_sym
      @options = options
      @steps = []
      @transitions = {}
    end
    
    # Add a step to the flow
    # @param id [Symbol, String] The step ID
    # @param options [Hash] Options for the step in this flow
    def step(id, options = {})
      @steps << { id: id.to_sym, options: options }
    end
    
    # Define a transition between steps
    # @param from [Symbol, String] The source step
    # @param to [Symbol, String] The destination step
    # @param condition [Proc] Optional condition for the transition
    def transition(from, to, condition = nil)
      @transitions[from.to_sym] ||= []
      @transitions[from.to_sym] << { to: to.to_sym, condition: condition }
    end
    
    # Get the next step after the current step
    # @param current_step [Symbol, String] The current step
    # @param form_submission [FormSubmission] The form submission
    # @return [Symbol, nil] The next step, or nil if there is no next step
    def next_step(current_step, form_submission = nil)
      current_step = current_step.to_sym
      
      # Check for transitions
      transitions = @transitions[current_step] || []
      
      # Find first matching transition
      transition = transitions.find do |t|
        t[:condition].nil? || (form_submission && t[:condition].call(form_submission))
      end
      
      return transition[:to] if transition
      
      # Fall back to default next step
      default_next_step(current_step)
    end
    
    # Get the previous step before the current step
    # @param current_step [Symbol, String] The current step
    # @param form_submission [FormSubmission] The form submission
    # @return [Symbol, nil] The previous step, or nil if there is no previous step
    def previous_step(current_step, form_submission = nil)
      current_step = current_step.to_sym
      current_index = step_index(current_step)
      return nil if current_index.nil? || current_index <= 0
      
      @steps[current_index - 1][:id]
    end
    
    # Check if the current step is the first step
    # @param current_step [Symbol, String] The current step
    # @return [Boolean] Whether the current step is the first step
    def first_step?(current_step)
      current_step = current_step.to_sym
      step_index(current_step) == 0
    end
    
    # Check if the current step is the last step
    # @param current_step [Symbol, String] The current step
    # @return [Boolean] Whether the current step is the last step
    def last_step?(current_step)
      current_step = current_step.to_sym
      step_index(current_step) == @steps.size - 1
    end
    
    # Get all step IDs in the flow
    # @return [Array<Symbol>] All step IDs
    def step_ids
      @steps.map { |s| s[:id] }
    end
    
    private
    
    # Get the index of a step in the flow
    # @param step_id [Symbol, String] The step ID
    # @return [Integer, nil] The index, or nil if the step is not in the flow
    def step_index(step_id)
      @steps.index { |s| s[:id] == step_id.to_sym }
    end
    
    # Get the default next step
    # @param current_step [Symbol] The current step
    # @return [Symbol, nil] The next step, or nil if there is no next step
    def default_next_step(current_step)
      current_index = step_index(current_step)
      return nil if current_index.nil? || current_index >= @steps.size - 1
      
      @steps[current_index + 1][:id]
    end
  end
end
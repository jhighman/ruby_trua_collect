# frozen_string_literal: true

module FormWizard
  class Flow
    attr_reader :steps, :navigation_rules, :completion_rules, :event_handlers
    
    class << self
      def flow_name(name)
        @flow_name = name
      end
      
      def step(step_name)
        @steps ||= []
        @steps << step_name
      end
      
      def navigate_to(target_step, options = {})
        @navigation_rules ||= []
        @navigation_rules << {
          target: target_step,
          from: options[:from],
          if: options[:if],
          unless: options[:unless]
        }
      end
      
      def complete_if(condition, options = {})
        @completion_rules ||= []
        @completion_rules << {
          condition: condition,
          after: options[:after]
        }
      end
      
      def on_complete(&block)
        @event_handlers ||= {}
        @event_handlers[:complete] = block
      end
      
      def on_step_complete(step_name, &block)
        @event_handlers ||= {}
        @event_handlers[:step_complete] ||= {}
        @event_handlers[:step_complete][step_name] = block
      end
      
      def inherited(subclass)
        FormWizard.register_flow(subclass)
      end
      
      def name
        @flow_name
      end
      
      def steps
        @steps || []
      end
      
      def navigation_rules
        @navigation_rules || []
      end
      
      def completion_rules
        @completion_rules || []
      end
      
      def event_handlers
        @event_handlers || {}
      end
    end
    
    def initialize
      @steps = self.class.steps
      @navigation_rules = self.class.navigation_rules
      @completion_rules = self.class.completion_rules
      @event_handlers = self.class.event_handlers
    end
    
    def name
      self.class.name
    end
    
    def initial_step
      steps.first
    end
    
    def next_step(current_step, form_submission = nil)
      # Check navigation rules
      if form_submission && navigation_rules.any?
        rule = navigation_rules.find do |r|
          r[:from].to_s == current_step.to_s &&
            (r[:if].nil? || evaluate_condition(r[:if], form_submission)) &&
            (r[:unless].nil? || !evaluate_condition(r[:unless], form_submission))
        end
        
        return rule[:target] if rule
      end
      
      # Default to next step in sequence
      current_index = steps.index(current_step.to_sym)
      return nil if current_index.nil? || current_index >= steps.length - 1
      
      steps[current_index + 1]
    end
    
    def previous_step(current_step)
      current_index = steps.index(current_step.to_sym)
      return nil if current_index.nil? || current_index <= 0
      
      steps[current_index - 1]
    end
    
    def should_complete?(form_submission, current_step)
      return false if completion_rules.empty?
      
      completion_rules.any? do |rule|
        (rule[:after].nil? || rule[:after].to_s == current_step.to_s) &&
          evaluate_condition(rule[:condition], form_submission)
      end
    end
    
    def trigger_complete(form_submission)
      return unless event_handlers[:complete]
      
      event_handlers[:complete].call(form_submission)
    end
    
    def trigger_step_complete(step_name, form_submission)
      return unless event_handlers[:step_complete] && event_handlers[:step_complete][step_name.to_sym]
      
      event_handlers[:step_complete][step_name.to_sym].call(form_submission)
    end
    
    private
    
    def evaluate_condition(condition, form_submission)
      if condition.is_a?(Proc)
        condition.call(form_submission)
      elsif condition.is_a?(Symbol) && respond_to?(condition, true)
        send(condition, form_submission)
      else
        false
      end
    end
  end
end
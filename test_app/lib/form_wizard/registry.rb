# frozen_string_literal: true

module FormWizard
  class Registry
    def initialize
      @registry = {}
    end
    
    def register(step_class)
      name = step_class.name
      return if name.nil?
      
      @registry[name.to_sym] = step_class
    end
    
    def find(name)
      return nil if name.nil?
      
      step_class = @registry[name.to_sym]
      return nil if step_class.nil?
      
      step_class.new
    end
    
    def all
      @registry.values.map(&:new)
    end
    
    def clear
      @registry = {}
    end
  end
end
# frozen_string_literal: true

module FormWizard
  class FlowRegistry
    def initialize
      @registry = {}
    end
    
    def register(flow_class)
      name = flow_class.name
      return if name.nil?
      
      @registry[name.to_sym] = flow_class
    end
    
    def find(name)
      return nil if name.nil?
      
      flow_class = @registry[name.to_sym]
      return nil if flow_class.nil?
      
      flow_class.new
    end
    
    def all
      @registry.values.map(&:new)
    end
    
    def clear
      @registry = {}
    end
  end
end
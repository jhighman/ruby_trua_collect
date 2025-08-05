# frozen_string_literal: true

module FormWizard
  autoload :Step, 'form_wizard/step'
  autoload :Field, 'form_wizard/field'
  autoload :Flow, 'form_wizard/flow'
  autoload :Registry, 'form_wizard/registry'
  autoload :FlowRegistry, 'form_wizard/flow_registry'
  autoload :EventManager, 'form_wizard/event_manager'
  
  # Services
  autoload :BaseService, 'form_wizard/services/base_service'
  autoload :FormSubmissionService, 'form_wizard/services/form_submission_service'
  autoload :NavigationService, 'form_wizard/services/navigation_service'
  autoload :ValidationService, 'form_wizard/services/validation_service'
  
  # Components will be added in a future update
  
  # Controller and Model concerns
  module Controller
    autoload :FormWizardConcern, 'form_wizard/concerns/controller/form_wizard_concern'
  end
  
  module Model
    autoload :FormWizardConcern, 'form_wizard/concerns/model/form_wizard_concern'
  end
  
  # Class methods
  class << self
    def configure
      yield self if block_given?
    end
    
    def register_step(step_class)
      registry.register(step_class)
    end
    
    def register_flow(flow_class)
      flow_registry.register(flow_class)
    end
    
    def find_step(step_name)
      registry.find(step_name)
    end
    
    def find_flow(flow_name)
      flow_registry.find(flow_name)
    end
    
    def registry
      @registry ||= Registry.new
    end
    
    def flow_registry
      @flow_registry ||= FlowRegistry.new
    end
    
    def event_manager
      @event_manager ||= EventManager.new
    end
    
    def on(event_name, &block)
      event_manager.subscribe(event_name, &block)
    end
    
    def trigger(event_name, *args)
      event_manager.publish(event_name, *args)
    end
  end
end

# Generators will be added in a future update
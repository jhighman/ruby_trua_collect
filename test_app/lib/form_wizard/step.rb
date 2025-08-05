# frozen_string_literal: true

module FormWizard
  class Step
    attr_reader :title, :description, :fields, :validations
    
    class << self
      def step_name(name)
        @step_name = name
      end
      
      def title(title)
        @title = title
      end
      
      def description(description)
        @description = description
      end
      
      def field(name, options = {})
        @fields ||= []
        @fields << Field.new(name, options)
      end
      
      def validate(method_name = nil, &block)
        @validations ||= []
        @validations << (method_name || block)
      end
      
      def inherited(subclass)
        FormWizard.register_step(subclass)
      end
      
      def name
        @step_name
      end
      
      def fields
        @fields || []
      end
      
      def validations
        @validations || []
      end
    end
    
    def initialize
      @title = self.class.instance_variable_get(:@title) || self.class.name.to_s.humanize
      @description = self.class.instance_variable_get(:@description)
      @fields = self.class.fields
      @validations = self.class.validations
      @errors = []
    end
    
    def name
      self.class.name
    end
    
    def validate(form_submission, params)
      @errors = []
      
      # Validate required fields
      fields.each do |field|
        if field.required? && params[field.name.to_s].blank?
          add_error(field.name, "#{field.label} is required")
        end
      end
      
      # Run custom validations
      validations.each do |validation|
        if validation.is_a?(Symbol)
          send(validation, form_submission, params)
        else
          instance_exec(form_submission, params, &validation)
        end
      end
      
      @errors.empty?
    end
    
    def add_error(field_name, message)
      @errors << "#{field_name}: #{message}"
    end
    
    def errors
      @errors
    end
    
    def should_display?(form_submission)
      true
    end
  end
end
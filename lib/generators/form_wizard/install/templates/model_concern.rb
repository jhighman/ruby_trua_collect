# frozen_string_literal: true

module FormWizard
  module Model
    extend ActiveSupport::Concern
    
    included do
      # Add any model-specific inclusions or configurations here
    end
    
    # Instance methods
    
    # Get a field value from the form data
    # @param field_name [Symbol, String] The name of the field
    # @return [Object] The value of the field
    def get_field_value(field_name)
      data[field_name.to_s]
    end
    
    # Set a field value in the form data
    # @param field_name [Symbol, String] The name of the field
    # @param value [Object] The value to set
    # @return [Object] The value that was set
    def set_field_value(field_name, value)
      self.data = data.merge(field_name.to_s => value)
      save
      value
    end
    
    # Get all field values for a specific step
    # @param step_name [Symbol, String] The name of the step
    # @return [Hash] The field values for the step
    def get_step_values(step_name)
      step = FormWizard.find_step(step_name)
      return {} unless step
      
      field_names = step.fields.map { |f| f.name.to_s }
      data.slice(*field_names)
    end
    
    # Set multiple field values at once
    # @param values [Hash] The field values to set
    # @return [Hash] The updated data hash
    def set_field_values(values)
      self.data = data.merge(values.stringify_keys)
      save
      data
    end
    
    # Check if a field has a value
    # @param field_name [Symbol, String] The name of the field
    # @return [Boolean] Whether the field has a value
    def has_field_value?(field_name)
      data.key?(field_name.to_s) && !data[field_name.to_s].nil?
    end
    
    # Clear a field value
    # @param field_name [Symbol, String] The name of the field
    # @return [Hash] The updated data hash
    def clear_field_value(field_name)
      self.data = data.except(field_name.to_s)
      save
      data
    end
    
    # Clear all field values
    # @return [Hash] The updated data hash
    def clear_all_field_values
      self.data = {}
      save
      data
    end
  end
end
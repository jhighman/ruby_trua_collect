# frozen_string_literal: true

class <%= step_name.camelize %>Step < FormWizard::Step
  # Define step attributes
  step_name :<%= step_name %>
  
  # Define fields with validations
<% fields.each do |field| %>
  field :<%= field[:name] %>, 
        type: :<%= field[:type] %>, 
        <%= "required: true," if field[:required] %>
        <%= "options: #{field[:options]}," if field[:options].present? %>
        label: '<%= field[:label] || field[:name].to_s.humanize %>'
<% end %>
  
  # Custom validations
  # validate :custom_validation
  
  # Custom methods
  # def custom_method
  #   # Your custom logic here
  # end
  
  # Conditional display
  # def should_display?(form_submission)
  #   # Your conditional logic here
  #   true
  # end
  
  # Custom field value processing
  # def process_field_value(field_name, value)
  #   # Process the value before saving
  #   value
  # end
  
  # Custom validation method
  # def custom_validation
  #   if get_field_value(:field_name) == 'invalid_value'
  #     add_error(:field_name, 'is not valid')
  #   end
  # end
end
# frozen_string_literal: true

# Register the <%= file_name %> step
FormWizard.define_step :<%= file_name %><% if step_position %>, position: <%= step_position %><% end %> do
  # Step configuration
  title "<%= step_title %>"
<% if step_description %>
  description "<%= step_description %>"
<% end %>
  
  # Fields
<% parse_fields.each do |field| %>
  field :<%= field[:name] %>, type: :<%= field[:type] %><% if field[:required] %>, required: true<% end %> do
    # Add validations if needed
    # validates :format, with: /\A[a-z]+\z/, message: "Only lowercase letters allowed"
  end
<% end %>
  
  # Custom validation logic (optional)
  validate do |values, form_submission|
    errors = {}
    
    # Add custom validation logic here
    # Example:
    # if values['password'] != values['password_confirmation']
    #   errors['password_confirmation'] = "Passwords don't match"
    # end
    
    errors
  end
  
  # Custom completion criteria (optional)
  completion_criteria do |values, form_submission|
    # By default, a step is complete when all required fields have values
    # You can override this with custom logic
    # Example:
    # values['terms_accepted'] == true && values['name'].present?
    
    # Default implementation:
    # required_fields = <%= parse_fields.select { |f| f[:required] }.map { |f| f[:name].to_s.inspect } %>
    # required_fields.all? { |field| values[field].present? }
    
    true # Return true to mark the step as complete
  end
end
# frozen_string_literal: true

class <%= flow_name.camelize %>Flow < FormWizard::Flow
  # Define flow attributes
  flow_name :<%= flow_name %>
  
  # Define steps in order
<% steps.each do |step| %>
  step :<%= step %>
<% end %>
  
  # Define navigation rules
  # Example:
  # navigate_to :step_two, from: :step_one, if: ->(form_submission) { form_submission.get_field_value(:some_field) == 'some_value' }
  # navigate_to :step_three, from: :step_one, unless: ->(form_submission) { form_submission.get_field_value(:some_field) == 'some_value' }
  
  # Define completion conditions
  # Example:
  # complete_if ->(form_submission) { form_submission.get_field_value(:opt_out) == 'yes' }, after: :opt_out_step
  
  # Define events
  # Example:
  # on_complete do |form_submission|
  #   # Your logic here
  #   # This will be called when the form is completed
  # end
  
  # on_step_complete :step_name do |form_submission|
  #   # Your logic here
  #   # This will be called when the specified step is completed
  # end
  
  # Define custom methods
  # Example:
  # def custom_method(form_submission)
  #   # Your custom logic here
  # end
end
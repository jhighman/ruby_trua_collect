# frozen_string_literal: true

# Register the <%= file_name %> flow
FormWizard.define_flow :<%= file_name %> do
  # Flow description: <%= flow_description %>
  
  # Add steps to the flow
<% flow_steps.each do |step| %>
  step :<%= step %>
<% end %>
  
  # Define transitions between steps
  # By default, steps are navigated in the order they are defined
  # You can define custom transitions based on conditions
  
  # Example: Skip employment history for students
  # transition :education, :signature, ->(form) {
  #   form.step_values('education')['occupation'] == 'student'
  # }
  
  # Example: Go to different step based on age
  # transition :personal_info, :senior_info, ->(form) {
  #   form.step_values('personal_info')['age'].to_i >= 65
  # }
  # transition :personal_info, :adult_info, ->(form) {
  #   form.step_values('personal_info')['age'].to_i < 65
  # }
end
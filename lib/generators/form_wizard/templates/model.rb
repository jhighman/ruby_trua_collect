# frozen_string_literal: true

class <%= class_name %> < ApplicationRecord
  belongs_to :requirements_config, optional: true
  belongs_to :user, optional: true
  
  has_many :audit_logs, dependent: :destroy, as: :auditable
  
  # Store steps as JSON
  serialize :steps, JSON
  
  # Store navigation_state as JSON if not using PostgreSQL with jsonb
  serialize :navigation_state, JSON unless column_for_attribute('navigation_state').type == :jsonb
  
<% if options[:dynamic_steps] || options[:multi_path] || options[:file_uploads] || options[:integrations] %>
  # Store advanced features as JSON if not using PostgreSQL with jsonb
  serialize :dynamic_steps, JSON unless column_for_attribute('dynamic_steps').type == :jsonb
  serialize :workflows, JSON unless column_for_attribute('workflows').type == :jsonb
  serialize :webhooks, JSON unless column_for_attribute('webhooks').type == :jsonb
  serialize :api_keys, JSON unless column_for_attribute('api_keys').type == :jsonb
  serialize :oauth_tokens, JSON unless column_for_attribute('oauth_tokens').type == :jsonb
  serialize :callbacks, JSON unless column_for_attribute('callbacks').type == :jsonb
  serialize :navigation_order, JSON unless column_for_attribute('navigation_order').type == :jsonb
<% end %>
  
  before_create :initialize_steps
  before_save :update_last_active_at
  
  # Get the values for a specific step
  def step_values(step_id)
    steps.dig(step_id, 'values') || steps.dig(step_id, :values) || {}
  end
  
  # Get the state for a specific step
  def step_state(step_id)
    steps[step_id] || {}
  end
  
  # Get the errors for a specific step
  def step_errors(step_id)
    steps.dig(step_id, 'errors') || steps.dig(step_id, :errors) || {}
  end
  
  # Check if a step is complete
  def step_complete?(step_id)
    steps.dig(step_id, 'is_complete') || steps.dig(step_id, :is_complete) || false
  end
  
  # Get all completed steps
  def completed_steps
    steps.select { |_, v| v['is_complete'] || v[:is_complete] }.keys
  end
  
  # Update the state for a specific step
  def update_step_state(step_id, state)
    # Initialize the step if it doesn't exist
    steps[step_id] ||= {}
    
    # Update the step state
    steps[step_id].merge!(state)
    
    # Save the changes
    save
  end
  
  # Move to a specific step
  def move_to_step(step_id)
    update(current_step_id: step_id)
  end
  
  # Check if the form is completed
  def completed?
    steps.all? { |_, v| v['is_complete'] || v[:is_complete] }
  end
  
  # Get a specific field value
  def get_field_value(field_id)
    steps.each do |_, step|
      values = step['values'] || step[:values] || {}
      return values[field_id] if values.key?(field_id)
    end
    nil
  end
  
  # Calculate progress percentage
  def progress_percentage
    total_steps = <%= class_name %>Config.step_ids.length
    completed_count = completed_steps.count
    
    return 0 if total_steps.zero?
    
    (completed_count.to_f / total_steps * 100).to_i
  end
  
  # Save the current navigation state
  def save_navigation_state(state = {})
    current_state = navigation_state || {}
    self.navigation_state = current_state.merge(state)
    save
  end
  
  # Get the last active time
  def last_active_time
    last_active_at || updated_at
  end
  
  # Check if the form has expired
  def expired?(expiration_hours = 24)
    Time.current - last_active_time > expiration_hours.hours
  end
  
  # Resume from a saved state
  def resume
    navigation_service = navigation
    navigation_service.resume_state
  end
  
  # Get the navigation service for this form submission
  def navigation
    @navigation_service ||= <%= class_name %>NavigationService.new(self)
  end
  
<% if options[:dynamic_steps] %>
  # Get the dynamic step service for this form submission
  def dynamic_steps_service
    @dynamic_step_service ||= <%= class_name %>DynamicStepService.new(self)
  end
<% end %>
  
<% if options[:multi_path] %>
  # Get the multi-path workflow service for this form submission
  def workflow
    @multi_path_workflow_service ||= <%= class_name %>MultiPathWorkflowService.new(self)
  end
<% end %>
  
<% if options[:file_uploads] %>
  # Get the file upload service for this form submission
  def file_upload
    @file_upload_service ||= <%= class_name %>FileUploadService.new(self)
  end
<% end %>
  
<% if options[:integrations] %>
  # Get the integration service for this form submission
  def integration
    @integration_service ||= <%= class_name %>IntegrationService.new(self)
  end
<% end %>
  
  private
  
  # Initialize steps with empty values
  def initialize_steps
    self.steps ||= {}
    self.navigation_state ||= {}
<% if options[:dynamic_steps] || options[:multi_path] || options[:file_uploads] || options[:integrations] %>
    self.dynamic_steps ||= {}
    self.workflows ||= {}
    self.webhooks ||= []
    self.api_keys ||= {}
    self.oauth_tokens ||= {}
    self.callbacks ||= {}
    self.navigation_order ||= []
<% end %>
  end
  
  # Update the last_active_at timestamp
  def update_last_active_at
    self.last_active_at = Time.current
  end
end
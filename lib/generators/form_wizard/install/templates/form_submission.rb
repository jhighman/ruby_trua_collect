# frozen_string_literal: true

# Model for storing form submissions
class FormSubmission < ApplicationRecord
  # Attributes
  # - id: integer - Primary key
  # - current_step_id: string - The current step ID
  # - steps: jsonb - Stores the form state for each step
  # - flow_name: string - The name of the flow
  # - user_id: integer - Reference to the user (optional)
  # - submitted_at: datetime - When the form was submitted
  # - created_at: datetime - When the record was created
  # - updated_at: datetime - When the record was last updated
  
  # Relationships
  belongs_to :user, optional: true
  
  # Validations
  validates :current_step_id, inclusion: { in: -> (record) { FormWizard.step_ids } }, allow_nil: true
  
  # Callbacks
  before_validation :set_default_values, on: :create
  
  # Initialize with default values
  def initialize(attributes = {})
    super
    set_default_values
  end
  
  # Get step state
  # @param step_id [Symbol, String] The step ID
  # @return [Hash] The step state
  def step_state(step_id)
    steps[step_id.to_s] || {}
  end
  
  # Get step values
  # @param step_id [Symbol, String] The step ID
  # @return [Hash] The step values
  def step_values(step_id)
    step_state(step_id)['values'] || {}
  end
  
  # Get step errors
  # @param step_id [Symbol, String] The step ID
  # @return [Hash] The step errors
  def step_errors(step_id)
    step_state(step_id)['errors'] || {}
  end
  
  # Check if step is valid
  # @param step_id [Symbol, String] The step ID
  # @return [Boolean] Whether the step is valid
  def step_valid?(step_id)
    step_state(step_id)['is_valid'] || false
  end
  
  # Check if step is complete
  # @param step_id [Symbol, String] The step ID
  # @return [Boolean] Whether the step is complete
  def step_complete?(step_id)
    step_state(step_id)['is_complete'] || false
  end
  
  # Update step state
  # @param step_id [Symbol, String] The step ID
  # @param state_updates [Hash] The state updates
  # @return [Boolean] Whether the update was successful
  def update_step_state(step_id, state_updates)
    current_state = step_state(step_id)
    self.steps = steps.merge(step_id.to_s => current_state.merge(state_updates))
    save
  end
  
  # Get all completed steps
  # @return [Array<String>] All completed step IDs
  def completed_steps
    steps.select { |_, state| state['is_complete'] }.keys
  end
  
  # Check if all steps are complete
  # @return [Boolean] Whether all steps are complete
  def complete?
    service = FormWizard::FormSubmissionService.new(self)
    service.navigation.available_steps.all? { |step_id| step_complete?(step_id) }
  end
  
  private
  
  # Set default values
  def set_default_values
    self.steps ||= {}
    self.flow_name ||= 'default'
    
    # Set current step to the first step if not set
    if current_step_id.blank? && FormWizard.step_ids.any?
      self.current_step_id = FormWizard.step_ids.first
    end
  end
end
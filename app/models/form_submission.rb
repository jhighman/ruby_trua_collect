class FormSubmission < ApplicationRecord
  # Attributes
  # - current_step_id: string - The current step ID
  # - steps: jsonb - Stores the form state for each step
  # - user_id: integer - Reference to the user (optional)
  # - session_id: string - Session identifier for guest users

  # Relationships
  belongs_to :user, optional: true
  belongs_to :requirements_config, optional: true

  # Validations
  validates :current_step_id, inclusion: { in: FormConfig.step_ids }, allow_nil: true

  # Initialize with default values
  def initialize(attributes = {})
    super
    self.steps ||= FormConfig.step_ids.each_with_object({}) do |step_id, hash|
      hash[step_id] = {
        values: {},
        errors: {},
        is_valid: false,
        is_complete: false,
        touched: [],
        _config: {}
      }
    end
    self.current_step_id ||= FormConfig.step_ids.first
    
    # Set default requirements_config if not provided
    self.requirements_config ||= RequirementsConfig.first_or_create
  end

  # Get step state
  def step_state(step_id)
    steps[step_id] || {}
  end

  # Get step values
  def step_values(step_id)
    step_state(step_id)[:values] || {}
  end

  # Get step errors
  def step_errors(step_id)
    step_state(step_id)[:errors] || {}
  end

  # Check if step is valid
  def step_valid?(step_id)
    step_state(step_id)[:is_valid] || false
  end

  # Check if step is complete
  def step_complete?(step_id)
    step_state(step_id)[:is_complete] || false
  end

  # Get step config
  def step_config(step_id)
    step_state(step_id)[:_config] || {}
  end

  # Get touched fields for a step
  def touched_fields(step_id)
    step_state(step_id)[:touched] || []
  end

  # Mark field as touched
  def touch_field(step_id, field_id)
    current_touched = touched_fields(step_id)
    unless current_touched.include?(field_id)
      steps[step_id][:touched] = current_touched + [field_id]
      save
    end
  end

  # Update step state
  def update_step_state(step_id, state_updates)
    current_state = step_state(step_id)
    steps[step_id] = current_state.merge(state_updates)
    save
  end

  # Move to a specific step
  def move_to_step(step_id)
    return false unless FormConfig.step_ids.include?(step_id)
    update(current_step_id: step_id)
  end

  # Get all completed steps
  def completed_steps
    steps.select { |_, state| state[:is_complete] }.keys
  end

  # Check if all steps are complete
  def complete?
    FormConfig.step_ids.all? { |step_id| step_complete?(step_id) }
  end
end
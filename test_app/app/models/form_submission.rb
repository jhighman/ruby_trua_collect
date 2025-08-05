# frozen_string_literal: true

class FormSubmission < ApplicationRecord
  include FormWizard::Model::FormWizardConcern
  
  # Store form data as JSON
  serialize :data, JSON
  
  # Validations
  validates :session_id, presence: true, uniqueness: true
  
  # Callbacks
  before_validation :initialize_data, on: :create
  
  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
  
  # Methods
  def initialize_data
    self.data ||= {}
    self.completed ||= false
    self.current_step ||= nil
  end
  
  def complete!
    update(completed: true)
    FormWizard.trigger(:form_completed, self)
  end
  
  def set_current_step(step)
    update(current_step: step)
  end
  
  def completed_steps
    data['_completed_steps'] || []
  end
  
  def mark_step_completed(step)
    steps = completed_steps
    steps << step unless steps.include?(step)
    self.data = data.merge('_completed_steps' => steps)
    save
  end
  
  def step_completed?(step)
    completed_steps.include?(step)
  end
  
  def progress_percentage(flow)
    return 100 if completed
    return 0 if completed_steps.empty?
    
    total_steps = flow.steps.count
    completed_count = completed_steps.count
    
    (completed_count.to_f / total_steps * 100).round
  end
end
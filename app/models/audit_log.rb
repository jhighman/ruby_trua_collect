# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :form_submission
  belongs_to :user, optional: true
  
  validates :step_id, presence: true
  validates :field, presence: true
  validates :timestamp, presence: true
  
  # Scopes for easier querying
  scope :for_step, ->(step_id) { where(step_id: step_id) }
  scope :for_field, ->(field) { where(field: field) }
  scope :recent_first, -> { order(timestamp: :desc) }
  
  # Returns a human-readable description of the change
  def change_description
    "#{field} changed from '#{old_value}' to '#{new_value}'"
  end
  
  # Returns the user who made the change, or 'System' if no user
  def changed_by
    user.present? ? user.email : 'System'
  end
end
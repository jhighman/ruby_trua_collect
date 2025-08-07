# frozen_string_literal: true

class AuditService
  # Log a change to a form submission field
  # @param form_submission [FormSubmission] The form submission being changed
  # @param step_id [String] The ID of the step being changed
  # @param field [String] The field being changed
  # @param old_value [Object] The previous value
  # @param new_value [Object] The new value
  # @param user_id [Integer, nil] The ID of the user making the change, if any
  # @return [AuditLog] The created audit log entry
  def self.log_change(form_submission, step_id, field, old_value, new_value, user_id = nil)
    # Skip logging if the values are the same
    return if old_value.to_s == new_value.to_s
    
    AuditLog.create!(
      form_submission_id: form_submission.id,
      step_id: step_id,
      field: field,
      old_value: old_value.to_s,
      new_value: new_value.to_s,
      user_id: user_id,
      timestamp: Time.current
    )
  end
  
  # Log multiple changes at once
  # @param form_submission [FormSubmission] The form submission being changed
  # @param step_id [String] The ID of the step being changed
  # @param changes [Hash] A hash of field => [old_value, new_value] pairs
  # @param user_id [Integer, nil] The ID of the user making the changes, if any
  # @return [Array<AuditLog>] The created audit log entries
  def self.log_changes(form_submission, step_id, changes, user_id = nil)
    logs = []
    
    changes.each do |field, (old_value, new_value)|
      log = log_change(form_submission, step_id, field, old_value, new_value, user_id)
      logs << log if log.present?
    end
    
    logs
  end
  
  # Get the history of changes for a form submission
  # @param form_submission [FormSubmission] The form submission to get history for
  # @param step_id [String, nil] The step ID to filter by, if any
  # @param limit [Integer] The maximum number of entries to return
  # @return [ActiveRecord::Relation<AuditLog>] The audit log entries
  def self.get_history(form_submission, step_id = nil, limit = 100)
    query = AuditLog.where(form_submission_id: form_submission.id)
    query = query.where(step_id: step_id) if step_id.present?
    query.order(timestamp: :desc).limit(limit)
  end
  
  # Get the history of changes for a specific field
  # @param form_submission [FormSubmission] The form submission to get history for
  # @param step_id [String] The step ID
  # @param field [String] The field name
  # @param limit [Integer] The maximum number of entries to return
  # @return [ActiveRecord::Relation<AuditLog>] The audit log entries
  def self.get_field_history(form_submission, step_id, field, limit = 20)
    AuditLog.where(
      form_submission_id: form_submission.id,
      step_id: step_id,
      field: field
    ).order(timestamp: :desc).limit(limit)
  end
end
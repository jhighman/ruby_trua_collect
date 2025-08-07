# frozen_string_literal: true

# AccumulatorStep is a concern that provides common functionality for steps that accumulate entries.
# It can be included in controllers or services that handle steps with iterative data capture.
#
# Usage:
#
# class MyController < ApplicationController
#   include AccumulatorStep
#
#   # Define the step_id for this accumulator
#   def accumulator_step_id
#     'my_step'
#   end
#
#   # Define the validation rules for this accumulator
#   def validate_entries(entries)
#     # Custom validation logic
#     { is_valid: true, errors: {} }
#   end
# end
#
module AccumulatorStep
  extend ActiveSupport::Concern

  included do
    helper_method :accumulator_entries if respond_to?(:helper_method)
    helper_method :accumulator_completion_status if respond_to?(:helper_method)
    helper_method :accumulator_can_move_next? if respond_to?(:helper_method)
  end

  # Override this method in the including class to specify the step_id
  def accumulator_step_id
    raise NotImplementedError, "#{self.class} must implement #accumulator_step_id"
  end

  # Override this method in the including class to specify the validation rules
  def validate_entries(entries)
    raise NotImplementedError, "#{self.class} must implement #validate_entries"
  end

  # Override this method in the including class to specify additional completion requirements
  def additional_completion_requirements_met?(values)
    true
  end

  # Get all entries for this accumulator
  def accumulator_entries
    values = @form_submission.step_values(accumulator_step_id) || {}
    values['entries'] || []
  end

  # Add an entry to this accumulator
  def add_accumulator_entry(entry)
    # Get the current entries
    current_entries = accumulator_entries
    
    # Add the new entry
    new_entries = current_entries + [entry]
    
    # Update the step state
    update_accumulator_entries(new_entries)
    
    # Return the updated entries
    accumulator_entries
  end

  # Remove an entry from this accumulator
  def remove_accumulator_entry(index)
    # Get the current entries
    current_entries = accumulator_entries
    
    # Remove the entry at the specified index
    if index < current_entries.length
      current_entries.delete_at(index)
      
      # Update the step state
      update_accumulator_entries(current_entries)
    end
    
    # Return the updated entries
    accumulator_entries
  end

  # Update all entries for this accumulator
  def update_accumulator_entries(entries)
    # Get the current values
    current_values = @form_submission.step_values(accumulator_step_id) || {}
    
    # Update the entries
    updated_values = current_values.merge('entries' => entries)
    
    # Validate the entries
    validation_result = validate_entries(entries)
    
    # Update the step state
    @form_submission.update_step_state(accumulator_step_id, {
      values: updated_values,
      is_valid: validation_result[:is_valid],
      errors: validation_result[:errors],
      is_complete: check_completion_status(updated_values, validation_result[:is_valid])
    })
    
    # Return the updated values
    @form_submission.step_values(accumulator_step_id)
  end

  # Check if the accumulator is complete
  def check_completion_status(values, is_valid)
    return false unless is_valid
    
    # Check if there are any entries
    entries = values['entries'] || []
    return false if entries.empty?
    
    # Check additional completion requirements
    additional_completion_requirements_met?(values)
  end

  # Get the completion status of this accumulator
  def accumulator_completion_status
    step_state = @form_submission.step_state(accumulator_step_id) || {}
    {
      is_valid: step_state[:is_valid] || step_state['is_valid'] || false,
      is_complete: step_state[:is_complete] || step_state['is_complete'] || false,
      errors: step_state[:errors] || step_state['errors'] || {}
    }
  end

  # Check if the user can move to the next step
  def accumulator_can_move_next?
    completion_status = accumulator_completion_status
    completion_status[:is_valid] && completion_status[:is_complete]
  end

  # Handle an accumulator entry submission
  def handle_accumulator_entry(params)
    # Extract the entry from the params
    entry = extract_entry_from_params(params)
    
    # Add the entry to the accumulator
    add_accumulator_entry(entry)
  end

  # Extract an entry from the params
  def extract_entry_from_params(params)
    # This is a basic implementation that assumes all params are part of the entry
    # Override this method in the including class for custom extraction logic
    params.to_h
  end

  # Handle the removal of an accumulator entry
  def handle_accumulator_entry_removal(params)
    index = params[:entry_index].to_i
    remove_accumulator_entry(index)
  end
end
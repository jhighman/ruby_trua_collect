# frozen_string_literal: true

class ConditionalLogicService
  attr_reader :form_submission

  def initialize(form_submission)
    @form_submission = form_submission
  end

  # Evaluate conditional logic for a step
  def evaluate_step_conditions(step_id, conditions = nil)
    # If no conditions provided, get them from the step configuration
    conditions ||= get_step_conditions(step_id)
    return true if conditions.blank?

    # Evaluate the conditions
    evaluate_conditions(conditions)
  end

  # Evaluate conditional logic for a field
  def evaluate_field_conditions(step_id, field_id, conditions = nil)
    # If no conditions provided, get them from the field configuration
    conditions ||= get_field_conditions(step_id, field_id)
    return true if conditions.blank?

    # Evaluate the conditions
    evaluate_conditions(conditions)
  end

  # Get the next step based on conditional logic
  def get_conditional_next_step(current_step_id)
    # Get the step configuration
    step_config = FormConfig.find_step(current_step_id)
    return nil unless step_config

    # Get the conditional next steps
    conditional_next_steps = step_config[:conditional_next_steps]
    return nil unless conditional_next_steps.present?

    # Evaluate each condition and return the first matching next step
    conditional_next_steps.each do |condition|
      if evaluate_conditions(condition[:conditions])
        return condition[:next_step]
      end
    end

    # If no conditions match, return the default next step
    step_config[:next_step]
  end

  # Get all available steps based on conditional logic
  def get_conditional_available_steps
    # Get all steps
    all_steps = FormConfig.step_ids

    # Filter steps based on conditional logic
    all_steps.select do |step_id|
      evaluate_step_conditions(step_id)
    end
  end

  # Get all fields for a step based on conditional logic
  def get_conditional_fields(step_id)
    # Get the step configuration
    step_config = FormConfig.find_step(step_id)
    return [] unless step_config

    # Get all fields for the step
    all_fields = step_config[:fields] || []

    # Filter fields based on conditional logic
    all_fields.select do |field|
      evaluate_field_conditions(step_id, field[:id])
    end
  end

  # Validate a step with conditional logic
  def validate_step_with_conditions(step_id, values)
    # Get the step configuration
    step_config = FormConfig.find_step(step_id)
    return { is_valid: false, errors: {} } unless step_config

    errors = {}
    is_valid = true

    # Get conditional fields for this step
    conditional_fields = get_conditional_fields(step_id)

    # Validate each conditional field
    conditional_fields.each do |field|
      # Skip if the field is not required or has a condition that evaluates to false
      next unless field[:required] && evaluate_field_conditions(step_id, field[:id])

      # Get the field value
      value = values[field[:id]]

      # Check if the field is required and empty
      if value.nil? || (value.is_a?(String) && value.empty?)
        errors[field[:id]] = "#{field[:label]} is required"
        is_valid = false
        next
      end

      # Validate the field based on its validation rules
      if field[:validation].present?
        field[:validation].each do |rule|
          case rule[:type]
          when 'pattern'
            if value.is_a?(String) && !rule[:value].match?(value)
              errors[field[:id]] = rule[:message]
              is_valid = false
              break
            end
          when 'minLength'
            if value.is_a?(String) && value.length < rule[:value]
              errors[field[:id]] = rule[:message]
              is_valid = false
              break
            end
          when 'maxLength'
            if value.is_a?(String) && value.length > rule[:value]
              errors[field[:id]] = rule[:message]
              is_valid = false
              break
            end
          when 'min'
            if value.to_i < rule[:value]
              errors[field[:id]] = rule[:message]
              is_valid = false
              break
            end
          when 'max'
            if value.to_i > rule[:value]
              errors[field[:id]] = rule[:message]
              is_valid = false
              break
            end
          when 'custom'
            # Custom validation rule
            if rule[:method].present? && respond_to?(rule[:method], true)
              result = send(rule[:method], value, values)
              if result.present?
                errors[field[:id]] = result
                is_valid = false
                break
              end
            end
          end
        end
      end
    end

    { is_valid: is_valid, errors: errors }
  end

  private

  # Get conditions for a step
  def get_step_conditions(step_id)
    # Get the step configuration
    step_config = FormConfig.find_step(step_id)
    return nil unless step_config

    # Get the conditions
    step_config[:conditions]
  end

  # Get conditions for a field
  def get_field_conditions(step_id, field_id)
    # Get the step configuration
    step_config = FormConfig.find_step(step_id)
    return nil unless step_config

    # Find the field
    field = step_config[:fields]&.find { |f| f[:id] == field_id }
    return nil unless field

    # Get the conditions
    field[:conditions]
  end

  # Evaluate a set of conditions
  def evaluate_conditions(conditions)
    return true if conditions.blank?

    # Handle different condition types
    case conditions[:type]
    when 'and'
      # All conditions must be true
      conditions[:conditions].all? { |condition| evaluate_conditions(condition) }
    when 'or'
      # At least one condition must be true
      conditions[:conditions].any? { |condition| evaluate_conditions(condition) }
    when 'not'
      # Negate the condition
      !evaluate_conditions(conditions[:condition])
    when 'equals'
      # Check if a field equals a value
      field_value = get_field_value(conditions[:field])
      field_value == conditions[:value]
    when 'notEquals'
      # Check if a field does not equal a value
      field_value = get_field_value(conditions[:field])
      field_value != conditions[:value]
    when 'contains'
      # Check if a field contains a value
      field_value = get_field_value(conditions[:field])
      field_value.to_s.include?(conditions[:value].to_s)
    when 'notContains'
      # Check if a field does not contain a value
      field_value = get_field_value(conditions[:field])
      !field_value.to_s.include?(conditions[:value].to_s)
    when 'greaterThan'
      # Check if a field is greater than a value
      field_value = get_field_value(conditions[:field])
      field_value.to_i > conditions[:value].to_i
    when 'lessThan'
      # Check if a field is less than a value
      field_value = get_field_value(conditions[:field])
      field_value.to_i < conditions[:value].to_i
    when 'empty'
      # Check if a field is empty
      field_value = get_field_value(conditions[:field])
      field_value.nil? || field_value == '' || (field_value.is_a?(Array) && field_value.empty?)
    when 'notEmpty'
      # Check if a field is not empty
      field_value = get_field_value(conditions[:field])
      !field_value.nil? && field_value != '' && (!field_value.is_a?(Array) || !field_value.empty?)
    when 'custom'
      # Custom condition
      if conditions[:method].present? && respond_to?(conditions[:method], true)
        send(conditions[:method], conditions[:params])
      else
        false
      end
    else
      # Unknown condition type
      false
    end
  end

  # Get the value of a field
  def get_field_value(field_path)
    # Parse the field path (e.g., "personal_info.first_name")
    parts = field_path.split('.')
    step_id = parts[0]
    field_id = parts[1]

    # Get the step values
    step_values = form_submission.step_values(step_id) || {}

    # Get the field value
    if field_id.present?
      step_values[field_id]
    else
      step_values
    end
  end
end
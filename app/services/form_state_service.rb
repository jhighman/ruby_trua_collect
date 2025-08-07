# frozen_string_literal: true

class FormStateService
  attr_reader :form_submission, :config, :requirements

  def initialize(form_submission, config = FormConfig, requirements = nil)
    @form_submission = form_submission
    @config = config
    @requirements = requirements || form_submission.requirements_config || RequirementsConfig.first_or_create
  end
  
  # Check if a step is an accumulator step
  def is_accumulator_step?(step_id)
    %w[education residence_history employment_history].include?(step_id)
  end
  
  # Check if a step is enabled based on requirements
  def is_step_enabled(step_id)
    # Cache the result for 1 hour
    Rails.cache.fetch("form_submission:#{form_submission.id}:step_enabled:#{step_id}", expires_in: 1.hour) do
      case step_id
      when 'consents'
        requirements.consents_required.values.any?
      when 'signature'
        requirements.signature['required']
      when 'personal_info'
        requirements.verification_steps['personalInfo']['enabled']
      when 'residence_history'
        requirements.verification_steps['residenceHistory']['enabled']
      when 'employment_history'
        requirements.verification_steps['employmentHistory']['enabled']
      when 'education'
        requirements.verification_steps['education']['enabled']
      when 'professional_licenses'
        requirements.verification_steps['professionalLicense']['enabled']
      else
        true # Default to enabled if not specified
      end
    end
  end
  
  # Get all available steps (enabled steps)
  def available_steps
    # Cache the result for 1 hour
    Rails.cache.fetch("form_submission:#{form_submission.id}:available_steps", expires_in: 1.hour) do
      config.step_ids.select { |step_id| is_step_enabled(step_id) }
    end
  end

  # Update step values and validate
  def update_step(step_id, values, user_id = nil)
    # Initialize step if it doesn't exist
    if !form_submission.steps[step_id]
      form_submission.steps[step_id] = {
        values: {},
        errors: {},
        is_valid: false,
        is_complete: false,
        touched: [],
        _config: {}
      }
      form_submission.save
    end
    
    step = form_submission.step_state(step_id) || {}
    
    # Extract config if present
    config_values = values.is_a?(Hash) && values.key?('_config') ? values.delete('_config') : {}
    
    # Get current values for audit trail
    old_values = step[:values] || {}
    
    # Update values, with special handling for entries arrays
    step_values = step[:values] || {}
    
    if values.is_a?(Hash) && values['entries'].is_a?(Array) && step_values['entries'].is_a?(Array)
      # For entries arrays, we want to replace the entire array, not merge
      step_values = step_values.merge(values)
    else
      # For other values, merge normally
      step_values = step_values.merge(values || {})
    end
    
    # Update config
    step_config = (step[:_config] || {}).merge(config_values || {})
    
    # Validate step
    validation_result = validate_step(step_id, step_values, step_config)
    
    # Update step state
    result = form_submission.update_step_state(step_id, {
      values: step_values,
      _config: step_config,
      is_valid: validation_result[:is_valid],
      errors: validation_result[:errors],
      is_complete: check_step_completion(step_id, step_values, validation_result[:is_valid], step_config)
    })
    
    # Log changes for audit trail
    log_step_changes(step_id, old_values, step_values, user_id)
    
    # Clear caches related to this step
    clear_step_caches(step_id)
    
    # Ensure changes are persisted
    form_submission.reload
    result
  end

  # Move to a specific step
  def move_to_step(step_id)
    old_step_id = form_submission.current_step_id
    form_submission.move_to_step(step_id)
    
    # Log navigation for audit trail
    AuditService.log_change(
      form_submission,
      'navigation',
      'current_step_id',
      old_step_id,
      step_id
    )
    
    # Clear navigation caches
    clear_navigation_caches
  end

  # Check if can move to next step
  def can_move_next?(step_id = nil)
    step_id ||= form_submission.current_step_id
    
    # Cache the result for 5 minutes
    Rails.cache.fetch("form_submission:#{form_submission.id}:can_move_next:#{step_id}", expires_in: 5.minutes) do
      current_step = form_submission.step_state(step_id)
      
      # Check if the current step is valid and complete
      step_valid = current_step&.dig(:is_valid) || current_step&.dig("is_valid")
      step_complete = current_step&.dig(:is_complete) || current_step&.dig("is_complete")
      
      return false unless step_valid && step_complete

      # Check if there's a next enabled step
      current_index = config.step_ids.index(step_id)
      return false unless current_index

      next_step_index = current_index + 1
      while next_step_index < config.step_ids.length
        next_step = config.step_ids[next_step_index]
        return true if is_step_enabled(next_step)
        next_step_index += 1
      end

      # No enabled next step found
      false
    end
  end

  # Check if can move to previous step
  def can_move_previous?
    # Cache the result for 5 minutes
    Rails.cache.fetch("form_submission:#{form_submission.id}:can_move_previous", expires_in: 5.minutes) do
      current_index = config.step_ids.index(form_submission.current_step_id)
      current_index > 0
    end
  end

  # Get navigation state
  def navigation_state(step_id = nil)
    step_id ||= form_submission.current_step_id
    
    # Cache the result for 5 minutes
    Rails.cache.fetch("form_submission:#{form_submission.id}:navigation_state:#{step_id}", expires_in: 5.minutes) do
      {
        can_move_next: can_move_next?(step_id),
        can_move_previous: can_move_previous?,
        available_steps: available_steps,
        completed_steps: form_submission.completed_steps
      }
    end
  end
  
  # Timeline entry methods
  def add_timeline_entry(step_id, entry, user_id = nil)
    # Initialize the step if it doesn't exist
    if !form_submission.steps[step_id]
      form_submission.steps[step_id] = {
        values: { 'entries' => [] },
        errors: {},
        is_valid: false,
        is_complete: false,
        touched: [],
        _config: {}
      }
      form_submission.save
    end
    
    # Get the current values and entries
    current_values = form_submission.step_values(step_id)
    current_entries = current_values['entries'] || []
    
    # Add the new entry
    new_entries = current_entries + [entry]
    
    # Update the step state
    form_submission.update_step_state(step_id, {
      values: current_values.merge('entries' => new_entries)
    })
    
    # Log the addition for audit trail
    AuditService.log_change(
      form_submission,
      step_id,
      'entries',
      "#{current_entries.length} entries",
      "#{new_entries.length} entries",
      user_id
    )
    
    # Clear caches related to this step
    clear_step_caches(step_id)
    
    # Return the updated entries
    form_submission.reload
    form_submission.step_values(step_id)['entries'] || []
  end

  def update_timeline_entry(step_id, index, entry, user_id = nil)
    # Ensure the step exists
    current_step = form_submission.steps[step_id] || {
      values: { 'entries' => [] },
      errors: {},
      is_valid: false,
      is_complete: false,
      touched: [],
      _config: {}
    }
    
    # Get current entries
    current_values = current_step[:values] || {}
    current_entries = current_values['entries'] || []
    
    # Update the entry at the specified index
    if index < current_entries.length
      old_entry = current_entries[index]
      current_entries[index] = entry
      
      # Update the step state directly
      current_step[:values] = current_values.merge('entries' => current_entries)
      form_submission.steps[step_id] = current_step
      form_submission.save!
      
      # Log the update for audit trail
      AuditService.log_change(
        form_submission,
        step_id,
        "entries[#{index}]",
        old_entry.to_json,
        entry.to_json,
        user_id
      )
      
      # Clear caches related to this step
      clear_step_caches(step_id)
    end
  end

  def remove_timeline_entry(step_id, index, user_id = nil)
    # Ensure the step exists
    current_step = form_submission.steps[step_id] || {
      values: { 'entries' => [] },
      errors: {},
      is_valid: false,
      is_complete: false,
      touched: [],
      _config: {}
    }
    
    # Get current entries
    current_values = current_step[:values] || {}
    current_entries = current_values['entries'] || []
    
    # Remove the entry at the specified index
    if index < current_entries.length
      removed_entry = current_entries[index]
      current_entries.delete_at(index)
      
      # Update the step state directly
      current_step[:values] = current_values.merge('entries' => current_entries)
      form_submission.steps[step_id] = current_step
      form_submission.save!
      
      # Log the removal for audit trail
      AuditService.log_change(
        form_submission,
        step_id,
        "entries[#{index}]",
        removed_entry.to_json,
        "REMOVED",
        user_id
      )
      
      # Clear caches related to this step
      clear_step_caches(step_id)
    end
  end

  def get_timeline_entries(step_id)
    # Cache the result for 5 minutes
    Rails.cache.fetch("form_submission:#{form_submission.id}:timeline_entries:#{step_id}", expires_in: 5.minutes) do
      # Initialize the step if it doesn't exist
      if !form_submission.steps[step_id]
        form_submission.steps[step_id] = {
          values: { 'entries' => [] },
          errors: {},
          is_valid: false,
          is_complete: false,
          touched: [],
          _config: {}
        }
        form_submission.save
      end
      
      # Get the entries from the step values
      values = form_submission.step_values(step_id)
      values['entries'] || []
    end
  end
  
  # Accumulator step methods
  
  # Get entries from an accumulator step
  def get_accumulator_entries(step_id)
    get_timeline_entries(step_id)
  end
  
  # Add an entry to an accumulator step
  def add_accumulator_entry(step_id, entry, user_id = nil)
    add_timeline_entry(step_id, entry, user_id)
  end
  
  # Remove an entry from an accumulator step
  def remove_accumulator_entry(step_id, index, user_id = nil)
    remove_timeline_entry(step_id, index, user_id)
  end
  
  # Update an entry in an accumulator step
  def update_accumulator_entry(step_id, index, entry, user_id = nil)
    update_timeline_entry(step_id, index, entry, user_id)
  end
  
  # Get the configuration for an accumulator step
  def get_accumulator_config(step_id)
    # Cache the result for 1 hour
    Rails.cache.fetch("accumulator_config:#{step_id}", expires_in: 1.hour) do
      # Get configuration from initializer
      if Rails.application.config.respond_to?(:accumulator_steps)
        config = Rails.application.config.accumulator_steps[step_id.to_sym]
        return config.with_indifferent_access if config.present?
      end
      
      # Fallback to hardcoded configuration
      case step_id
      when 'education'
        {
          entry_name: 'Education',
          entry_name_plural: 'Education Entries',
          required_entries: 1,
          validation_method: :validate_education_entries
        }
      when 'residence_history'
        {
          entry_name: 'Residence',
          entry_name_plural: 'Residences',
          required_entries: 1,
          required_years: 3,
          validation_method: :validate_residence_entries
        }
      when 'employment_history'
        {
          entry_name: 'Employment',
          entry_name_plural: 'Employment History',
          required_entries: 1,
          required_years: 3,
          validation_method: :validate_employment_entries
        }
      else
        {}
      end
    end
  end

  # Validate a step
  def validate_step(step_id, values, step_config = {})
    step_config = config.find_step(step_id)
    return { is_valid: false, errors: {} } unless step_config

    errors = {}
    is_valid = true

    # Validate consents
    if step_id == 'consents'
      consents_config = step_config[:_config] || {}
      consents_required = consents_config['consents_required'] || {}
      consents_valid = consents_required.all? do |key, required|
        !required || values["#{key}_consent"] == true
      end
      unless consents_valid
        errors['consents'] = 'All required consents must be provided'
        is_valid = false
      end
    end

    # Validate accumulator steps
    if is_accumulator_step?(step_id)
      # Get accumulator config
      config = get_accumulator_config(step_id)
      entries = values['entries'] || []
      
      # Check if entries exist when required
      if entries.empty? && config[:required_entries] > 0
        errors['timeline'] = "At least one #{config[:entry_name].downcase} entry is required"
        is_valid = false
      else
        # Validate entries using the appropriate method
        validation_method = config[:validation_method]
        if validation_method && respond_to?(validation_method, true)
          validation_result = send(validation_method, entries, values)
          
          if validation_result[:error].present?
            errors['timeline'] = validation_result[:error]
            is_valid = false
          end
        end
      end
    end

    # Validate education-specific fields
    if step_id == 'education'
      highest_level = values['highest_level']
      
      if highest_level.blank?
        errors['highest_level'] = 'Highest education level is required'
        is_valid = false
      elsif highest_level.in?(%w[college masters doctorate]) && (values['entries'] || []).empty?
        errors['entries'] = 'At least one education entry is required for college or higher education'
        is_valid = false
      end
    end

    # Validate fields
    step_config[:fields].each do |field|
      value = values[field[:id]]
      error = validate_field(field, value)
      if error.present?
        errors[field[:id]] = error
        is_valid = false
      end
    end

    { is_valid: is_valid, errors: errors }
  end

  # Get step value
  def get_step_value(step_id, field_id)
    # Cache the result for 5 minutes
    Rails.cache.fetch("form_submission:#{form_submission.id}:step_value:#{step_id}:#{field_id}", expires_in: 5.minutes) do
      form_submission.step_values(step_id)[field_id]
    end
  end

  # Check if step is complete
  def is_step_complete(step_id)
    # Cache the result for 5 minutes
    Rails.cache.fetch("form_submission:#{form_submission.id}:step_complete:#{step_id}", expires_in: 5.minutes) do
      form_submission.step_complete?(step_id)
    end
  end
  
  # Submit the form
  def submit_form(user_id = nil)
    # Ensure form_submission is up to date
    form_submission.reload
    
    # Check if all available steps are complete
    incomplete_steps = available_steps.reject { |step_id| form_submission.step_complete?(step_id) }
    
    if incomplete_steps.any?
      return { success: false, errors: { submit: 'Incomplete form' } }
    end
    
    # Log form completion for audit trail
    AuditService.log_change(
      form_submission,
      'form',
      'status',
      'in_progress',
      'completed',
      user_id
    )
    
    # Clear all caches for this form submission
    clear_all_caches
    
    # Return success
    { success: true, form_state: form_submission.steps }
  end

  private

  # Log changes to step values for audit trail
  def log_step_changes(step_id, old_values, new_values, user_id = nil)
    # Skip if old_values is nil
    return unless old_values.is_a?(Hash)
    
    # Find all changed fields
    changes = {}
    
    # Handle regular fields
    new_values.each do |field, value|
      if old_values[field] != value && field != 'entries'
        changes[field] = [old_values[field], value]
      end
    end
    
    # Handle entries separately (they're arrays)
    if new_values['entries'].is_a?(Array) && old_values['entries'].is_a?(Array)
      old_count = old_values['entries'].length
      new_count = new_values['entries'].length
      
      if old_count != new_count
        changes['entries_count'] = [old_count, new_count]
      end
    end
    
    # Log all changes
    AuditService.log_changes(form_submission, step_id, changes, user_id)
  end
  
  # Validate a field
  def validate_field(field, value)
    if field[:required] && (value.nil? || (value.is_a?(String) && value.empty?))
      return "#{field[:label]} is required"
    end
    
    if field[:validation]
      field[:validation].each do |rule|
        case rule[:type]
        when 'pattern'
          return rule[:message] if value.is_a?(String) && !rule[:value].match?(value)
        when 'minLength'
          return rule[:message] if value.is_a?(String) && value.length < rule[:value]
        when 'maxLength'
          return rule[:message] if value.is_a?(String) && value.length > rule[:value]
        end
      end
    end
    
    nil
  end
  
  # Validate education entries
  def validate_education_entries(entries, values)
    # Check for highest education level
    highest_level = values['highest_level']
    
    if highest_level.blank?
      return { error: 'Highest education level is required', total_years: 0 }
    end
    
    # For high school, no entries are required
    return { error: nil, total_years: 0 } if highest_level == 'high_school' && entries.empty?
    
    # For college or higher, at least one entry is required
    if highest_level.in?(%w[college masters doctorate]) && entries.empty?
      return { error: 'At least one education entry is required for college or higher education', total_years: 0 }
    end
    
    # Validate timeline
    optimized_validate_timeline(entries, 3)
  end
  
  # Validate residence entries
  def validate_residence_entries(entries, values)
    # Get required years from config
    config = get_accumulator_config('residence_history')
    required_years = config[:required_years] || 3
    
    # Validate timeline
    optimized_validate_timeline(entries, required_years)
  end
  
  # Validate employment entries
  def validate_employment_entries(entries, values)
    # Get required years from config
    config = get_accumulator_config('employment_history')
    required_years = config[:required_years] || 3
    
    # Validate timeline
    optimized_validate_timeline(entries, required_years)
  end

  # Optimized timeline validation algorithm
  def optimized_validate_timeline(entries, required_years = 3)
    return { error: "Please add at least one entry", total_years: 0 } if entries.empty?

    today = Date.today
    required_start = today - required_years.years
    
    # Parse dates once and cache the results
    parsed_entries = entries.map do |entry|
      {
        start_date: parse_date(entry['start_date']),
        end_date: entry['is_current'] ? today : parse_date(entry['end_date']),
        is_current: entry['is_current'],
        identifier: entry['institution'] || entry['address'] || entry['employer']
      }
    end
    
    # Validate date formats
    invalid_entries = parsed_entries.select { |e| e[:start_date].nil? || (!e[:is_current] && e[:end_date].nil?) }
    if invalid_entries.any?
      invalid_items = invalid_entries.map { |e| e[:identifier] }.join(", ")
      return {
        error: "Please check the dates for: #{invalid_items}. All dates must be in a valid format (YYYY-MM-DD).",
        total_years: 0
      }
    end
    
    # Check for end dates before start dates
    invalid_ranges = parsed_entries.select { |e| !e[:is_current] && e[:end_date] < e[:start_date] }
    if invalid_ranges.any?
      invalid_items = invalid_ranges.map { |e| e[:identifier] }.join(", ")
      return {
        error: "End date cannot be before start date for: #{invalid_items}",
        total_years: 0
      }
    end
    
    # Sort entries by start date (oldest first)
    sorted_entries = parsed_entries.sort_by { |e| e[:start_date] }
    
    # Create a timeline of date ranges
    timeline = []
    sorted_entries.each do |entry|
      timeline << {
        start_date: entry[:start_date],
        end_date: entry[:end_date]
      }
    end
    
    # Merge overlapping ranges
    merged_timeline = merge_date_ranges(timeline)
    
    # Calculate total years covered
    total_years = merged_timeline.sum do |range|
      (range[:end_date] - range[:start_date]).to_f / 365.25
    end
    
    # Check if the required period is covered
    if required_years > 0
      # Check if the most recent entry extends to today
      most_recent_end = merged_timeline.last[:end_date]
      
      if most_recent_end < today
        gap_start = most_recent_end
        return {
          error: "Your history has a gap between #{gap_start.strftime('%b %Y')} and today. Please add any missing entries or update the 'Current' checkbox.",
          total_years: total_years
        }
      end
      
      # Check if the timeline covers the required period
      earliest_start = merged_timeline.first[:start_date]
      
      if earliest_start > required_start
        years_missing = ((required_start - earliest_start).to_f / 365.25).abs.round(1)
        return {
          error: "Your history must cover at least #{required_years} years. You're missing approximately #{years_missing} years of history.",
          total_years: total_years
        }
      end
      
      # Check for gaps in the timeline
      previous_end = nil
      merged_timeline.each do |range|
        if previous_end && range[:start_date] > previous_end
          gap_start = previous_end
          gap_end = range[:start_date]
          return {
            error: "Your history has a gap between #{gap_start.strftime('%b %Y')} and #{gap_end.strftime('%b %Y')}. Please add any missing entries during this period.",
            total_years: total_years
          }
        end
        previous_end = range[:end_date]
      end
    end
    
    # All validations passed
    { total_years: total_years, error: nil }
  end
  
  # Helper method to parse dates
  def parse_date(date_string)
    return nil unless date_string.present?
    
    # Use Rails.cache to cache parsed dates
    Rails.cache.fetch("date_parse:#{date_string}", expires_in: 1.day) do
      begin
        Date.parse(date_string)
      rescue
        nil
      end
    end
  end
  
  # Helper method to merge overlapping date ranges
  def merge_date_ranges(ranges)
    return [] if ranges.empty?
    
    # Sort ranges by start date
    sorted_ranges = ranges.sort_by { |range| range[:start_date] }
    
    # Initialize result with the first range
    result = [sorted_ranges.first]
    
    # Merge overlapping ranges
    sorted_ranges[1..-1].each do |current_range|
      previous_range = result.last
      
      if current_range[:start_date] <= previous_range[:end_date]
        # Ranges overlap, merge them
        previous_range[:end_date] = [previous_range[:end_date], current_range[:end_date]].max
      else
        # Ranges don't overlap, add the current range to the result
        result << current_range
      end
    end
    
    result
  end
  
  # Legacy method for backward compatibility
  def calculate_timeline_coverage(entries)
    result = optimized_validate_timeline(entries, 5)
    {
      total_years: result[:total_years],
      has_continuous_coverage: result[:error].nil?
    }
  end

  # Check if step is complete
  def check_step_completion(step_id, values, is_valid, step_config = {})
    return false unless is_valid
    
    step_definition = config.find_step(step_id)
    return false unless step_definition

    # Handle consents step
    if step_id == 'consents'
      consents_config = step_config['consents_required'] || {}
      return consents_config.all? { |key, required| !required || values["#{key}_consent"] == true }
    end
    
    # Handle accumulator steps
    if is_accumulator_step?(step_id)
      # Get accumulator config
      accumulator_config = get_accumulator_config(step_id)
      entries = values['entries'] || []
      
      # Check if entries exist when required
      if accumulator_config[:required_entries] > 0 && entries.empty?
        return false
      end
      
      # For education step, check highest level
      if step_id == 'education'
        highest_level = values['highest_level']
        return false if highest_level.blank?
        
        # For high school, no entries are required
        return true if highest_level == 'high_school'
        
        # For college or higher, at least one entry is required
        return false if highest_level.in?(%w[college masters doctorate]) && entries.empty?
      end
      
      # For other accumulator steps, check if entries exist
      return !entries.empty?
    end

    # Handle regular steps
    required_fields = step_definition[:fields].select { |f| f[:required] }.map { |f| f[:id] }
    required_fields.all? do |field_id|
      value = values[field_id]
      value.is_a?(TrueClass) || !value.nil? && (!value.is_a?(String) || !value.empty?)
    end
  end
  
  # Clear caches related to a specific step
  def clear_step_caches(step_id)
    Rails.cache.delete("form_submission:#{form_submission.id}:step_enabled:#{step_id}")
    Rails.cache.delete("form_submission:#{form_submission.id}:can_move_next:#{step_id}")
    Rails.cache.delete("form_submission:#{form_submission.id}:navigation_state:#{step_id}")
    Rails.cache.delete("form_submission:#{form_submission.id}:timeline_entries:#{step_id}")
    Rails.cache.delete("form_submission:#{form_submission.id}:step_complete:#{step_id}")
    
    # Also clear navigation caches
    clear_navigation_caches
  end
  
  # Clear navigation caches
  def clear_navigation_caches
    Rails.cache.delete("form_submission:#{form_submission.id}:available_steps")
    Rails.cache.delete("form_submission:#{form_submission.id}:can_move_previous")
    
    # Clear navigation state for all steps
    config.step_ids.each do |step_id|
      Rails.cache.delete("form_submission:#{form_submission.id}:navigation_state:#{step_id}")
    end
  end
  
  # Clear all caches for this form submission
  def clear_all_caches
    # Clear step caches
    config.step_ids.each do |step_id|
      clear_step_caches(step_id)
    end
    
    # Clear navigation caches
    clear_navigation_caches
  end
end
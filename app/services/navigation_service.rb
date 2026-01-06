# frozen_string_literal: true

class NavigationService
  attr_reader :form_submission, :requirements_config, :lazy_loader
  
  def initialize(form_submission)
    @form_submission = form_submission
    @requirements_config = form_submission.requirements_config
    @lazy_loader = LazyLoadingService.new(form_submission)
  end
  
  # Get all available steps (enabled steps)
  def available_steps
    # Cache the result for 1 hour
    Rails.cache.fetch("available_steps:#{form_submission.id}", expires_in: 1.hour) do
      # Get all enabled steps except review
      enabled_steps = FormConfig.step_ids.select { |step_id| step_id != 'review' && is_step_enabled(step_id) }
      
      # Add review as the last step if there are any enabled steps
      enabled_steps << 'review' if enabled_steps.any?
      
      enabled_steps
    end
  end
  
  # Check if a step is enabled based on requirements
  def is_step_enabled(step_id)
    # Cache the result for 1 hour
    Rails.cache.fetch("step_enabled:#{form_submission.id}:#{step_id}", expires_in: 1.hour) do
      case step_id
      when 'consents'
        requirements_config.consents_required.values.any?
      when 'signature'
        requirements_config.signature['required']
      when 'personal_info'
        requirements_config.verification_steps['personalInfo']['enabled']
      when 'residence_history'
        requirements_config.verification_steps['residenceHistory']['enabled']
      when 'employment_history'
        requirements_config.verification_steps['employmentHistory']['enabled']
      when 'education'
        requirements_config.verification_steps['education']['enabled']
      when 'professional_licenses'
        requirements_config.verification_steps['professionalLicense']['enabled']
      when 'review'
        # Review step is always enabled
        true
      else
        true # Default to enabled if not specified
      end
    end
  end
  
  # Get the next step in the flow
  def next_step(current_step_id)
    # Cache the result for 5 minutes
    Rails.cache.fetch("next_step:#{form_submission.id}:#{current_step_id}", expires_in: 5.minutes) do
      steps = available_steps
      current_index = steps.index(current_step_id)
      return nil unless current_index
      
      next_index = current_index + 1
      return nil if next_index >= steps.length
      
      steps[next_index]
    end
  end
  
  # Find the next step (even if the current step is not complete)
  def find_next_step(current_step_id)
    next_step(current_step_id)
  end
  
  # Get the previous step in the flow
  def previous_step(current_step_id)
    # Cache the result for 5 minutes
    Rails.cache.fetch("previous_step:#{form_submission.id}:#{current_step_id}", expires_in: 5.minutes) do
      steps = available_steps
      current_index = steps.index(current_step_id)
      return nil unless current_index && current_index > 0
      
      steps[current_index - 1]
    end
  end
  
  # Check if can move to next step
  def can_move_next?(step_id = nil)
    step_id ||= form_submission.current_step_id
    current_step = form_submission.step_state(step_id)
    
    # Check if the current step is valid and complete
    step_valid = current_step&.dig(:is_valid) || current_step&.dig("is_valid")
    step_complete = current_step&.dig(:is_complete) || current_step&.dig("is_complete")
    
    return false unless step_valid && step_complete
    
    # Check if there's a next enabled step
    next_step(step_id).present?
  end
  
  # Check if can move to previous step
  def can_move_previous?(step_id = nil)
    step_id ||= form_submission.current_step_id
    previous_step(step_id).present?
  end
  
  # Get navigation state
  def navigation_state(step_id = nil)
    step_id ||= form_submission.current_step_id
    
    # Cache the result for 5 minutes
    Rails.cache.fetch("navigation_state:#{form_submission.id}:#{step_id}", expires_in: 5.minutes) do
      next_step_id = next_step(step_id)
      
      # Preload the next step data if it exists
      lazy_loader.preload_next_step(step_id) if next_step_id
      
      {
        can_move_next: can_move_next?(step_id),
        can_move_previous: can_move_previous?(step_id),
        available_steps: available_steps,
        completed_steps: form_submission.completed_steps,
        current_step: step_id,
        next_step: next_step_id,
        previous_step: previous_step(step_id)
      }
    end
  end
  
  # Navigate to the next step
  def navigate_to_next(user_id = nil)
    current_step_id = form_submission.current_step_id
    next_step_id = next_step(current_step_id)
    
    if next_step_id
      # Log navigation for audit trail
      AuditService.log_change(
        form_submission,
        'navigation',
        'current_step_id',
        current_step_id,
        next_step_id,
        user_id
      )
      
      # Update form submission
      form_submission.update(current_step_id: next_step_id)
      
      # Save navigation state
      save_state
      
      # Clear navigation caches
      clear_navigation_caches(current_step_id)
      
      # Preload data for the next step
      preload_next_step(next_step_id)
      
      next_step_id
    else
      nil
    end
  end
  
  # Navigate to the previous step
  def navigate_to_previous(user_id = nil)
    current_step_id = form_submission.current_step_id
    prev_step_id = previous_step(current_step_id)
    
    if prev_step_id
      # Log navigation for audit trail
      AuditService.log_change(
        form_submission,
        'navigation',
        'current_step_id',
        current_step_id,
        prev_step_id,
        user_id
      )
      
      # Update form submission
      form_submission.update(current_step_id: prev_step_id)
      
      # Save navigation state
      save_state
      
      # Clear navigation caches
      clear_navigation_caches(current_step_id)
      
      # Preload data for the next step after the previous step
      preload_next_step(prev_step_id)
      
      prev_step_id
    else
      nil
    end
  end
  
  # Navigate to a specific step
  def navigate_to_step(step_id, user_id = nil)
    if available_steps.include?(step_id)
      current_step_id = form_submission.current_step_id
      
      # Log navigation for audit trail
      AuditService.log_change(
        form_submission,
        'navigation',
        'current_step_id',
        current_step_id,
        step_id,
        user_id
      )
      
      # Update form submission
      form_submission.update(current_step_id: step_id)
      
      # Save navigation state
      save_state
      
      # Clear navigation caches
      clear_navigation_caches(current_step_id)
      
      # Preload data for the next step
      preload_next_step(step_id)
      
      step_id
    else
      nil
    end
  end
  
  # Save the current navigation state
  def save_state
    # Save the current navigation state to the form submission
    form_submission.update(
      navigation_state: {
        current_step_id: form_submission.current_step_id,
        completed_steps: form_submission.completed_steps,
        last_active_at: Time.current
      }
    )
  end
  
  # Resume from a saved state
  def resume_state
    # Get the saved navigation state
    saved_state = form_submission.navigation_state || {}
    
    # Resume from the saved state if it exists
    if saved_state['current_step_id'].present?
      form_submission.update(current_step_id: saved_state['current_step_id'])
    else
      # If no saved state, start from the first available step
      form_submission.update(current_step_id: available_steps.first)
    end
    
    form_submission.current_step_id
  end
  
  # Check if the form has expired
  def expired?(expiration_hours = 24)
    # Get the saved navigation state
    saved_state = form_submission.navigation_state || {}
    
    # Check if the form has expired
    if saved_state['last_active_at'].present?
      last_active_at = Time.parse(saved_state['last_active_at'])
      Time.current - last_active_at > expiration_hours.hours
    else
      # If no last_active_at, check created_at
      Time.current - form_submission.created_at > expiration_hours.hours
    end
  end
  
  # Get the first incomplete step
  def first_incomplete_step
    available_steps.find { |step_id| !form_submission.step_complete?(step_id) }
  end
  
  # Get the completion percentage
  def completion_percentage
    total_steps = available_steps.length
    completed_count = form_submission.completed_steps.count
    
    return 0 if total_steps.zero?
    
    (completed_count.to_f / total_steps * 100).to_i
  end
  
  # Preload data for the next step
  def preload_next_step(current_step_id)
    next_step_id = find_next_step(current_step_id)
    lazy_loader.preload_next_step(current_step_id) if next_step_id
  end
  
  # Clear navigation caches
  def clear_navigation_caches(step_id)
    Rails.cache.delete("navigation_state:#{form_submission.id}:#{step_id}")
    Rails.cache.delete("next_step:#{form_submission.id}:#{step_id}")
    Rails.cache.delete("previous_step:#{form_submission.id}:#{step_id}")
    Rails.cache.delete("can_move_next:#{form_submission.id}:#{step_id}")
    Rails.cache.delete("can_move_previous:#{form_submission.id}:#{step_id}")
  end
end
# frozen_string_literal: true

class LazyLoadingService
  attr_reader :form_submission

  def initialize(form_submission)
    @form_submission = form_submission
  end

  # Lazy load a step's data
  def lazy_load_step(step_id)
    # Cache key for this step's data
    cache_key = "lazy_load:#{form_submission.id}:#{step_id}:#{form_submission.updated_at.to_i}"
    
    # Try to get data from cache
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      # Load data based on step type
      case step_id
      when 'residence_history', 'employment_history', 'education'
        load_accumulator_step(step_id)
      when 'personal_info'
        load_personal_info_step
      when 'consents'
        load_consents_step
      when 'signature'
        load_signature_step
      else
        load_generic_step(step_id)
      end
    end
  end

  # Preload data for the next step
  def preload_next_step(current_step_id)
    # Get navigation service
    navigation = form_submission.navigation
    
    # Find the next step
    next_step = navigation.find_next_step(current_step_id)
    
    # Preload data for the next step if it exists
    lazy_load_step(next_step) if next_step
  end

  private

  # Load data for an accumulator step
  def load_accumulator_step(step_id)
    # Get form state service
    form_state = FormStateService.new(form_submission)
    
    # Get entries and values
    entries = form_state.get_accumulator_entries(step_id)
    values = form_submission.step_values(step_id) || {}
    
    # Get accumulator config
    config = form_state.get_accumulator_config(step_id)
    
    # Calculate requirements status
    requirements = calculate_requirements(step_id, entries, values)
    
    # Return data
    {
      entries: entries,
      values: values,
      config: config,
      requirements: requirements
    }
  end

  # Load data for the personal info step
  def load_personal_info_step
    # Get values
    values = form_submission.step_values('personal_info') || {}
    
    # Return data
    {
      values: values
    }
  end

  # Load data for the consents step
  def load_consents_step
    # Get values
    values = form_submission.step_values('consents') || {}
    
    # Get requirements config
    requirements_config = form_submission.requirements_config
    
    # Get consents required
    consents_required = requirements_config.consents_required
    
    # Return data
    {
      values: values,
      consents_required: consents_required
    }
  end

  # Load data for the signature step
  def load_signature_step
    # Get values
    values = form_submission.step_values('signature') || {}
    
    # Return data
    {
      values: values
    }
  end

  # Load data for a generic step
  def load_generic_step(step_id)
    # Get values
    values = form_submission.step_values(step_id) || {}
    
    # Return data
    {
      values: values
    }
  end

  # Calculate requirements for an accumulator step
  def calculate_requirements(step_id, entries, values)
    # Get errors
    errors = form_submission.step_errors(step_id) || {}
    
    # Get configuration
    config = Rails.application.config.accumulator_steps[step_id.to_sym] rescue nil
    
    if config && config[:requirements].present?
      # Use configuration to define requirements
      config[:requirements].map do |req|
        # Check if requirement is met
        met = case req[:check_method].to_sym
              when :has_entries?
                entries.any?
              when :has_valid_dates?
                !errors['timeline'].present?
              when :covers_required_years?
                !errors['timeline'].present? && entries.any?
              else
                false
              end
        
        # Get error message
        error_key = case req[:check_method].to_sym
                    when :has_entries?
                      'entries'
                    when :has_valid_dates?
                      'timeline'
                    else
                      nil
                    end
        
        {
          name: req[:name],
          met: met,
          error: error_key ? errors[error_key] : nil
        }
      end
    else
      # Fallback to hardcoded requirements based on step type
      case step_id
      when 'residence_history'
        has_entries = entries.any?
        has_valid_dates = !errors['timeline'].present?
        covers_required_years = !errors['timeline'].present? && entries.any?
        
        [
          {
            name: 'Add at least one residence',
            met: has_entries,
            error: errors['entries']
          },
          {
            name: 'Ensure all dates are valid',
            met: has_valid_dates,
            error: errors['timeline']
          },
          {
            name: 'Cover the past 7 years of residence history',
            met: covers_required_years,
            error: errors['timeline']
          }
        ]
      when 'employment_history'
        has_entries = entries.any?
        has_valid_dates = !errors['timeline'].present?
        covers_required_years = !errors['timeline'].present? && entries.any?
        
        [
          {
            name: 'Add at least one employment',
            met: has_entries,
            error: errors['entries']
          },
          {
            name: 'Ensure all dates are valid',
            met: has_valid_dates,
            error: errors['timeline']
          },
          {
            name: 'Cover the past 7 years of employment history',
            met: covers_required_years,
            error: errors['timeline']
          }
        ]
      when 'education'
        has_entries = entries.any?
        has_valid_dates = !errors['timeline'].present?
        has_highest_level = values['highest_level'].present?
        
        [
          {
            name: 'Select highest education level',
            met: has_highest_level,
            error: errors['highest_level']
          },
          {
            name: 'Add education entries for college or higher',
            met: values['highest_level'] == 'high_school' || has_entries,
            error: errors['entries']
          },
          {
            name: 'Ensure all dates are valid',
            met: has_valid_dates,
            error: errors['timeline']
          }
        ]
      else
        []
      end
    end
  end
end
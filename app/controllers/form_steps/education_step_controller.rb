# frozen_string_literal: true

module FormSteps
  class EducationStepController < ApplicationController
    include AccumulatorStep
    
    before_action :set_form_submission
    
    # GET /form_steps/education
    def show
      @step_id = accumulator_step_id
      @form_state = FormStateService.new(@form_submission)
      @navigation_state = @form_state.navigation_state(@step_id)
      
      # Get entries and values
      @entries = accumulator_entries
      @values = @form_submission.step_values(@step_id) || {}
      @highest_level = @values['highest_level']
      
      # Calculate requirements status
      @requirements = calculate_requirements
      @completion_percentage = calculate_completion_percentage
      
      render 'form_steps/education/show'
    end
    
    # PATCH /form_steps/education
    def update
      @step_id = accumulator_step_id
      @form_state = FormStateService.new(@form_submission)
      
      if params[:commit] == 'Add Entry'
        # Handle adding a new education entry
        handle_accumulator_entry(params[:form_submission])
        redirect_to form_steps_education_path, status: :see_other
      elsif params[:commit] == 'Update Education Level'
        # Handle updating the highest education level
        update_highest_level(params[:form_submission][:highest_level])
        redirect_to form_steps_education_path, status: :see_other
      elsif params[:commit] == 'Next'
        # Handle navigation to next step
        next_step = find_next_enabled_step
        if next_step
          @form_submission.update!(current_step_id: next_step)
          redirect_to form_submission_path(step_id: next_step), status: :see_other
        else
          redirect_to complete_form_submission_path, status: :see_other
        end
      elsif params[:commit] == 'Previous'
        # Handle navigation to previous step
        prev_step = find_previous_enabled_step
        if prev_step
          @form_submission.update!(current_step_id: prev_step)
          redirect_to form_submission_path(step_id: prev_step), status: :see_other
        else
          redirect_to form_steps_education_path, status: :see_other
        end
      else
        # Stay on current step
        @navigation_state = @form_state.navigation_state(@step_id)
        render 'form_steps/education/show'
      end
    end
    
    # DELETE /form_steps/education
    def destroy
      entry_index = params[:entry_index].to_i
      remove_accumulator_entry(entry_index)
      redirect_to form_steps_education_path, status: :see_other
    end
    
    private
    
    # Define the step_id for this accumulator
    def accumulator_step_id
      'education'
    end
    
    # Extract entry from params
    def extract_entry_from_params(params)
      # Get configuration
      config = Rails.application.config.accumulator_steps[:education] rescue nil
      
      if config && config[:fields].present?
        # Use configuration to extract fields
        entry = {}
        
        config[:fields].each do |field|
          field_name = field[:name]
          
          # Handle special case for is_current and end_date
          if field_name == 'is_current'
            entry['is_current'] = params['is_current'] == '1'
          elsif field_name == 'end_date'
            entry['end_date'] = params['is_current'] == '1' ? nil : params['end_date']
          else
            entry[field_name] = params[field_name]
          end
        end
        
        entry
      else
        # Fallback to hardcoded extraction
        {
          'institution' => params['institution'],
          'degree' => params['degree'],
          'field_of_study' => params['field_of_study'],
          'location' => params['location'],
          'start_date' => params['start_date'],
          'end_date' => params['is_current'] == '1' ? nil : params['end_date'],
          'is_current' => params['is_current'] == '1'
        }
      end
    end
    
    # Validate entries
    def validate_entries(entries)
      # Get highest level
      values = @form_submission.step_values(accumulator_step_id) || {}
      highest_level = values['highest_level']
      
      # Get configuration
      config = Rails.application.config.accumulator_steps[:education] rescue nil
      
      errors = {}
      is_valid = true
      
      # Check if highest level is set (from additional_fields config)
      if config && config[:additional_fields].present?
        highest_level_field = config[:additional_fields].find { |f| f[:name] == 'highest_level' }
        if highest_level_field && highest_level_field[:required] && highest_level.blank?
          errors['highest_level'] = 'Highest education level is required'
          is_valid = false
        end
      elsif highest_level.blank?
        # Fallback to hardcoded validation
        errors['highest_level'] = 'Highest education level is required'
        is_valid = false
      end
      
      # Check if entries exist when required
      required_entries = config ? config[:required_entries] : 1
      
      if entries.empty? && required_entries > 0
        errors['timeline'] = 'At least one education entry is required'
        is_valid = false
      elsif highest_level.in?(%w[college masters doctorate]) && entries.empty?
        errors['entries'] = 'At least one education entry is required for college or higher education'
        is_valid = false
      else
        # Validate timeline coverage
        coverage = validate_timeline(entries)
        
        if coverage[:error].present?
          errors['timeline'] = coverage[:error]
          is_valid = false
        end
      end
      
      { is_valid: is_valid, errors: errors }
    end
    
    # Check additional completion requirements
    def additional_completion_requirements_met?(values)
      # Get configuration
      config = Rails.application.config.accumulator_steps[:education] rescue nil
      
      highest_level = values['highest_level']
      entries = values['entries'] || []
      
      # Check if highest level is required
      if config && config[:additional_fields].present?
        highest_level_field = config[:additional_fields].find { |f| f[:name] == 'highest_level' }
        return false if highest_level_field && highest_level_field[:required] && highest_level.blank?
      else
        # Fallback to hardcoded validation
        return false if highest_level.blank?
      end
      
      # For high school, no entries are required
      return true if highest_level == 'high_school'
      
      # For college or higher, at least one entry is required
      required_entries = config ? config[:required_entries] : 1
      return false if required_entries > 0 && entries.empty?
      
      # All requirements met
      true
    end
    
    # Update highest education level
    def update_highest_level(highest_level)
      # Get current values
      current_values = @form_submission.step_values(accumulator_step_id) || {}
      
      # Update highest level
      updated_values = current_values.merge('highest_level' => highest_level)
      
      # Update step state
      @form_state.update_step(accumulator_step_id, updated_values)
    end
    
    # Validate timeline entries for continuous coverage
    def validate_timeline(entries)
      # Get configuration
      config = Rails.application.config.accumulator_steps[:education] rescue nil
      entry_name = config ? config[:entry_name].downcase : 'education entry'
      
      return { error: "Please add at least one #{entry_name}", total_years: 0 } if entries.empty?

      today = Date.today
      
      # Convert string dates to Date objects and sort entries by start date (most recent first)
      sorted_entries = entries.map do |entry|
        {
          start_date: entry['start_date'].is_a?(String) ? (begin Date.parse(entry['start_date']) rescue nil end) : entry['start_date'],
          end_date: entry['is_current'] ? today : (entry['end_date'].is_a?(String) ? (begin Date.parse(entry['end_date']) rescue nil end) : entry['end_date']),
          is_current: entry['is_current'],
          institution: entry['institution']
        }
      end
      
      # Validate date formats
      invalid_entries = sorted_entries.select { |e| e[:start_date].nil? || (!e[:is_current] && e[:end_date].nil?) }
      if invalid_entries.any?
        invalid_schools = invalid_entries.map { |e| e[:institution] }.join(", ")
        return {
          error: "Please check the dates for: #{invalid_schools}. All dates must be in a valid format (YYYY-MM-DD).",
          total_years: 0
        }
      end
      
      # Check for end dates before start dates
      invalid_ranges = sorted_entries.select { |e| !e[:is_current] && e[:end_date] < e[:start_date] }
      if invalid_ranges.any?
        invalid_schools = invalid_ranges.map { |e| e[:institution] }.join(", ")
        return {
          error: "End date cannot be before start date for: #{invalid_schools}",
          total_years: 0
        }
      end
      
      # Check for required years coverage if specified in config
      if config && config[:required_years].present?
        required_years = config[:required_years]
        total_years = calculate_total_years(sorted_entries)
        
        if total_years < required_years
          years_missing = (required_years - total_years).round(1)
          return {
            error: "Your education history must cover at least #{required_years} years. You're missing approximately #{years_missing} years of history.",
            total_years: total_years
          }
        end
      end
      
      # All validations passed
      { total_years: calculate_total_years(sorted_entries), error: nil }
    end
    
    # Calculate total years of education
    def calculate_total_years(entries)
      total_years = 0
      
      entries.each do |entry|
        start_date = entry[:start_date]
        end_date = entry[:is_current] ? Date.today : entry[:end_date]
        
        # Calculate years for this entry
        years = (end_date - start_date).to_f / 365.25
        total_years += years
      end
      
      total_years
    end
    
    # Calculate requirements for display
    def calculate_requirements
      values = @form_submission.step_values(accumulator_step_id) || {}
      entries = values['entries'] || []
      errors = @form_submission.step_errors(accumulator_step_id) || {}
      highest_level = values['highest_level']
      
      # Get configuration
      config = Rails.application.config.accumulator_steps[:education] rescue nil
      
      if config && config[:requirements].present?
        # Use configuration to define requirements
        config[:requirements].map do |req|
          # Check if requirement is met
          met = case req[:check_method].to_sym
                when :has_highest_level?
                  highest_level.present?
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
                      when :has_highest_level?
                        'highest_level'
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
        # Fallback to hardcoded requirements
        has_highest_level = highest_level.present?
        has_entries = entries.any?
        has_valid_dates = !errors['timeline'].present?
        
        [
          {
            name: 'Select your highest education level',
            met: has_highest_level,
            error: errors['highest_level']
          },
          {
            name: 'Add at least one education entry',
            met: has_entries,
            error: errors['entries']
          },
          {
            name: 'Ensure all dates are valid',
            met: has_valid_dates,
            error: errors['timeline']
          }
        ]
      end
    end
    
    # Calculate completion percentage
    def calculate_completion_percentage
      requirements = calculate_requirements
      completed = requirements.count { |r| r[:met] }
      (completed.to_f / requirements.length * 100).to_i
    end
    
    # Find the next enabled step
    def find_next_enabled_step
      current_index = FormConfig.step_ids.index(accumulator_step_id)
      return nil unless current_index
      
      # Find the next enabled step
      ((current_index + 1)...FormConfig.step_ids.length).each do |i|
        step_id = FormConfig.step_ids[i]
        return step_id if @form_state.is_step_enabled(step_id)
      end
      
      nil
    end
    
    # Find the previous enabled step
    def find_previous_enabled_step
      current_index = FormConfig.step_ids.index(accumulator_step_id)
      return nil unless current_index
      
      # Find the previous enabled step
      (0...current_index).reverse_each do |i|
        step_id = FormConfig.step_ids[i]
        return step_id if @form_state.is_step_enabled(step_id)
      end
      
      nil
    end
    
    # Set form submission
    def set_form_submission
      if user_signed_in?
        @form_submission = current_user.form_submissions.find_by(id: session[:form_submission_id])
        
        if @form_submission.nil?
          @form_submission = current_user.form_submissions.find_or_create_by(id: params[:id])
        end
      else
        if session[:form_submission_id].present?
          @form_submission = FormSubmission.find_by(session_id: session[:form_submission_id])
        end
        
        if @form_submission.nil? && params[:id].present?
          @form_submission = FormSubmission.find_by(id: params[:id])
        end
        
        if @form_submission.nil?
          @form_submission = FormSubmission.create(
            session_id: SecureRandom.uuid,
            current_step_id: 'personal_info',
            requirements_config_id: RequirementsConfig.first.id
          )
          session[:form_submission_id] = @form_submission.session_id
        end
      end
      
      # Ensure requirements_config is set
      if @form_submission.requirements_config.nil?
        @form_submission.update(requirements_config: RequirementsConfig.first_or_create)
      end
    end
  end
end
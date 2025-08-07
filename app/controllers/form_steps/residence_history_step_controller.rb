# frozen_string_literal: true

module FormSteps
  class ResidenceHistoryStepController < ApplicationController
    include AccumulatorStep
    
    before_action :set_form_submission
    
    # Add required libraries
    require 'digest/md5'
    
    # GET /form_steps/residence_history
    def show
      @step_id = accumulator_step_id
      @form_state = FormStateService.new(@form_submission)
      @navigation = @form_submission.navigation
      @navigation_state = @navigation.navigation_state(@step_id)
      
      # Cache key for this view's data
      cache_key = "residence_history:#{@form_submission.id}:#{@form_submission.updated_at.to_i}"
      
      # Try to get data from cache
      cached_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        # Get entries and values
        entries = accumulator_entries
        values = @form_submission.step_values(@step_id) || {}
        
        # Calculate requirements status
        requirements = calculate_requirements
        completion_percentage = calculate_completion_percentage
        
        # Calculate years covered for timeline visualization
        years_data = if entries.any?
          # Get configuration
          config = Rails.application.config.accumulator_steps[:residence_history] rescue nil
          required_years = config && config[:required_years].present? ? config[:required_years] : 7
          
          # Use the optimized timeline validation
          validation_result = optimized_validate_timeline(entries, required_years)
          {
            years_covered: validation_result[:total_years].round(1),
            required_years: required_years
          }
        else
          {
            years_covered: 0,
            required_years: 7
          }
        end
        
        # Return all data as a hash
        {
          entries: entries,
          values: values,
          requirements: requirements,
          completion_percentage: completion_percentage,
          years_covered: years_data[:years_covered],
          required_years: years_data[:required_years]
        }
      end
      
      # Assign cached data to instance variables
      @entries = cached_data[:entries]
      @values = cached_data[:values]
      @requirements = cached_data[:requirements]
      @completion_percentage = cached_data[:completion_percentage]
      @years_covered = cached_data[:years_covered]
      @required_years = cached_data[:required_years]
      
      render 'form_steps/residence_history/show'
    end
    
    # PATCH /form_steps/residence_history
    def update
      @step_id = accumulator_step_id
      @form_state = FormStateService.new(@form_submission)
      @navigation = @form_submission.navigation
      
      if params[:commit] == 'Add Entry'
        # Handle adding a new residence entry
        handle_accumulator_entry(params[:form_submission])
        redirect_to form_steps_residence_history_path, status: :see_other
      elsif params[:commit] == 'Next'
        # Handle navigation to next step
        next_step = @navigation.navigate_to_next(current_user&.id)
        if next_step
          redirect_to form_submission_path(step_id: next_step), status: :see_other
        else
          redirect_to complete_form_submission_path, status: :see_other
        end
      elsif params[:commit] == 'Previous'
        # Handle navigation to previous step
        prev_step = @navigation.navigate_to_previous(current_user&.id)
        if prev_step
          redirect_to form_submission_path(step_id: prev_step), status: :see_other
        else
          redirect_to form_steps_residence_history_path, status: :see_other
        end
      elsif params[:commit] == 'Save and Exit'
        # Save the current state and redirect to the dashboard
        @navigation.save_state
        redirect_to root_path, notice: 'Your progress has been saved. You can resume later.' and return
      else
        # Stay on current step
        @navigation_state = @navigation.navigation_state(@step_id)
        render 'form_steps/residence_history/show'
      end
    end
    
    # DELETE /form_steps/residence_history
    def destroy
      entry_index = params[:entry_index].to_i
      remove_accumulator_entry(entry_index)
      redirect_to form_steps_residence_history_path, status: :see_other
    end
    
    private
    
    # Define the step_id for this accumulator
    def accumulator_step_id
      'residence_history'
    end
    
    # Extract entry from params
    def extract_entry_from_params(params)
      # Get configuration
      config = Rails.application.config.accumulator_steps[:residence_history] rescue nil
      
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
          'address' => params['address'],
          'city' => params['city'],
          'state' => params['state'],
          'zip' => params['zip'],
          'start_date' => params['start_date'],
          'end_date' => params['is_current'] == '1' ? nil : params['end_date'],
          'is_current' => params['is_current'] == '1'
        }
      end
    end
    
    # Validate entries
    def validate_entries(entries)
      errors = {}
      is_valid = true
      
      # Get configuration
      config = Rails.application.config.accumulator_steps[:residence_history] rescue nil
      
      # Check if entries exist when required
      required_entries = config ? config[:required_entries] : 1
      
      if entries.empty? && required_entries > 0
        errors['timeline'] = 'At least one residence entry is required'
        is_valid = false
      else
        # Use the optimized timeline validation
        validation_result = optimized_validate_timeline(entries)
        
        if validation_result[:error].present?
          errors['timeline'] = validation_result[:error]
          is_valid = false
        end
      end
      
      { is_valid: is_valid, errors: errors }
    end
    
    # Check additional completion requirements
    def additional_completion_requirements_met?(values)
      # Get configuration
      config = Rails.application.config.accumulator_steps[:residence_history] rescue nil
      
      entries = values['entries'] || []
      
      # Check if entries exist when required
      required_entries = config ? config[:required_entries] : 1
      return false if required_entries > 0 && entries.empty?
      
      # All requirements met
      true
    end
    
    # Optimized timeline validation algorithm
    def optimized_validate_timeline(entries, required_years = 7)
      return { error: "Please add at least one residence", total_years: 0 } if entries.empty?

      # Generate a cache key based on entries and required years
      entries_hash = Digest::MD5.hexdigest(entries.to_json)
      cache_key = "timeline_validation:#{entries_hash}:#{required_years}"
      
      # Try to get validation result from cache
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        today = Date.today
        required_start = today - required_years.years
        
        # Process entries in batches for large datasets
        batch_size = 100
        parsed_entries = []
        
        entries.each_slice(batch_size) do |batch|
          batch_parsed = batch.map do |entry|
            {
              start_date: parse_date(entry['start_date']),
              end_date: entry['is_current'] ? today : parse_date(entry['end_date']),
              is_current: entry['is_current'],
              address: entry['address']
            }
          end
          parsed_entries.concat(batch_parsed)
        end
        
        # Validate date formats
        invalid_entries = parsed_entries.select { |e| e[:start_date].nil? || (!e[:is_current] && e[:end_date].nil?) }
        if invalid_entries.any?
          invalid_addresses = invalid_entries.map { |e| e[:address] }.compact.join(", ")
          return {
            error: "Please check the dates for: #{invalid_addresses}. All dates must be in a valid format (YYYY-MM-DD).",
            total_years: 0
          }
        end
        
        # Check for end dates before start dates
        invalid_ranges = parsed_entries.select { |e| !e[:is_current] && e[:end_date] < e[:start_date] }
        if invalid_ranges.any?
          invalid_addresses = invalid_ranges.map { |e| e[:address] }.compact.join(", ")
          return {
            error: "End date cannot be before start date for: #{invalid_addresses}",
            total_years: 0
          }
        end
        
        # Sort entries by start date (oldest first)
        sorted_entries = parsed_entries.sort_by { |e| e[:start_date] }
        
        # Create a timeline of date ranges (more efficiently)
        timeline = sorted_entries.map { |entry| { start_date: entry[:start_date], end_date: entry[:end_date] } }
        
        # Merge overlapping ranges
        merged_timeline = merge_date_ranges(timeline)
        
        # Calculate total years covered (more efficiently)
        total_years = merged_timeline.sum { |range| (range[:end_date] - range[:start_date]).to_f / 365.25 }
        
        # Check if the required period is covered
        if required_years > 0
          # Check if the most recent entry extends to today
          most_recent_end = merged_timeline.last[:end_date]
          
          if most_recent_end < today
            gap_start = most_recent_end
            return {
              error: "Your residence history has a gap between #{gap_start.strftime('%b %Y')} and today. Please add any missing residences or update the 'Currently living here' checkbox.",
              total_years: total_years
            }
          end
          
          # Check if the timeline covers the required period
          earliest_start = merged_timeline.first[:start_date]
          
          if earliest_start > required_start
            years_missing = ((required_start - earliest_start).to_f / 365.25).abs.round(1)
            return {
              error: "Your residence history must cover the past #{required_years} years. You're missing approximately #{years_missing} years of history.",
              total_years: total_years
            }
          end
          
          # Check for gaps in the timeline (more efficiently)
          gaps = merged_timeline.each_cons(2).select { |prev, curr| curr[:start_date] > prev[:end_date] }
          if gaps.any?
            gap = gaps.first
            gap_start = gap[0][:end_date]
            gap_end = gap[1][:start_date]
            return {
              error: "Your residence history has a gap between #{gap_start.strftime('%b %Y')} and #{gap_end.strftime('%b %Y')}. Please add any missing residences during this period.",
              total_years: total_years
            }
          end
        end
        
        # All validations passed
        { total_years: total_years, error: nil }
      end
    end
    
    # Helper method to parse dates
    def parse_date(date_string)
      return nil unless date_string.present?
      
      # Use Rails.cache to cache parsed dates with a longer expiration
      Rails.cache.fetch("date_parse:#{date_string}", expires_in: 7.days) do
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
      
      # Generate a cache key based on the ranges
      ranges_hash = Digest::MD5.hexdigest(ranges.to_json)
      cache_key = "merge_date_ranges:#{ranges_hash}"
      
      # Try to get merged ranges from cache
      Rails.cache.fetch(cache_key, expires_in: 1.day) do
        # Sort ranges by start date
        sorted_ranges = ranges.sort_by { |range| range[:start_date] }
        
        # Initialize result with the first range
        result = [sorted_ranges.first.dup]
        
        # Merge overlapping ranges
        sorted_ranges[1..-1].each do |current_range|
          previous_range = result.last
          
          if current_range[:start_date] <= previous_range[:end_date]
            # Ranges overlap, merge them
            previous_range[:end_date] = [previous_range[:end_date], current_range[:end_date]].max
          else
            # Ranges don't overlap, add the current range to the result
            result << current_range.dup
          end
        end
        
        result
      end
    end
    
    # Calculate requirements for display
    def calculate_requirements
      # Cache key for requirements
      cache_key = "requirements:#{@form_submission.id}:#{@form_submission.updated_at.to_i}"
      
      # Try to get requirements from cache
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        values = @form_submission.step_values(accumulator_step_id) || {}
        entries = values['entries'] || []
        errors = @form_submission.step_errors(accumulator_step_id) || {}
        
        # Get configuration
        config = Rails.application.config.accumulator_steps[:residence_history] rescue nil
        
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
          # Fallback to hardcoded requirements
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
        end
      end
    end
    
    # Calculate completion percentage
    def calculate_completion_percentage
      # Cache key for completion percentage
      cache_key = "completion_percentage:#{@form_submission.id}:#{@form_submission.updated_at.to_i}"
      
      # Try to get completion percentage from cache
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        requirements = calculate_requirements
        completed = requirements.count { |r| r[:met] }
        (completed.to_f / requirements.length * 100).to_i
      end
    end
    
    # Set form submission
    def set_form_submission
      # Cache key for form submission
      cache_key = if user_signed_in?
        "form_submission:user:#{current_user.id}:#{session[:form_submission_id]}"
      else
        "form_submission:session:#{session[:form_submission_id]}"
      end
      
      # Try to get form submission from cache
      @form_submission = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        if user_signed_in?
          form_submission = current_user.form_submissions.find_by(id: session[:form_submission_id])
          
          if form_submission.nil?
            form_submission = current_user.form_submissions.find_or_create_by(id: params[:id])
          end
        else
          form_submission = nil
          
          if session[:form_submission_id].present?
            form_submission = FormSubmission.find_by(session_id: session[:form_submission_id])
          end
          
          if form_submission.nil? && params[:id].present?
            form_submission = FormSubmission.find_by(id: params[:id])
          end
          
          if form_submission.nil?
            form_submission = FormSubmission.create(
              session_id: SecureRandom.uuid,
              current_step_id: 'residence_history',
              requirements_config_id: RequirementsConfig.first.id
            )
            session[:form_submission_id] = form_submission.session_id
          end
        end
        
        # Ensure requirements_config is set
        if form_submission.requirements_config.nil?
          form_submission.update(requirements_config: RequirementsConfig.first_or_create)
        end
        
        form_submission
      end
    end
  end
end
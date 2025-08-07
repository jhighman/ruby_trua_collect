class FormSubmissionsController < ApplicationController
  before_action :set_form_submission
  before_action :check_form_expiration, except: [:show, :complete, :audit_trail]
  before_action :set_lazy_loader, only: [:show, :update, :complete, :resume]
  
  # GET /form
  # GET /form/:id
  def show
    # Default to residence_history step for testing
    @step_id = params[:step_id] || 'residence_history'
    
    # Initialize navigation service
    @navigation = @form_submission.navigation
    
    # Check if step exists
    unless FormConfig.step_ids.include?(@step_id)
      redirect_to form_submission_path(id: @form_submission.id, step_id: 'residence_history') and return
    end
    
    # Check if step is enabled based on requirements
    unless @navigation.is_step_enabled(@step_id)
      # Find the first enabled step
      enabled_step = @navigation.available_steps.first
      redirect_to form_submission_path(id: @form_submission.id, step_id: enabled_step) and return
    end
    
    # Get navigation state
    @navigation_state = @navigation.navigation_state(@step_id)
    
    # Get requirements
    @requirements = @form_submission.requirements_config
    
    # Lazy load the step data
    @step_data = @lazy_loader.lazy_load_step(@step_id)
    
    # For residence_history, use the new form_steps view
    if @step_id == 'residence_history'
      redirect_to form_steps_residence_history_path and return
    else
      # Preload the next step data
      @navigation.preload_next_step(@step_id)
      
      render "form_submissions/steps/#{@step_id}"
    end
  end
  
  # PATCH /form/:id
  def update
    # First, update the current_step_id to match the step_id parameter
    # This ensures we're working with the correct step
    if @form_submission.current_step_id != params[:step_id]
      @form_submission.update!(current_step_id: params[:step_id])
      @form_submission.reload
    end
    
    @form_state = FormStateService.new(@form_submission)
    @navigation = @form_submission.navigation
    @step_id = params[:step_id]
    
    # Get form values from params
    values = params[:form_submission]&.to_unsafe_h || {}
    
    # Special handling for education entries
    if @step_id == 'education' && params[:commit] == 'Add Education'
      handle_education_entry(values)
      redirect_to form_submission_path(id: @form_submission.id, step_id: @step_id), status: :see_other and return
    else
      # Update step state
      @form_state.update_step(@step_id, values, current_user&.id)
    end
    
    # Reload the form submission to ensure we have the latest data
    @form_submission.reload
    
    # Handle navigation
    if params[:commit] == 'Next'
      # Navigate to the next step
      next_step = @navigation.navigate_to_next(current_user&.id)
      
      if next_step
        redirect_to form_submission_path(id: @form_submission.id, step_id: next_step), status: :see_other and return
      else
        # No more steps, go to completion page
        redirect_to complete_form_submission_path, status: :see_other and return
      end
    elsif params[:commit] == 'Previous'
      # Navigate to the previous step
      prev_step = @navigation.navigate_to_previous(current_user&.id)
      
      if prev_step
        redirect_to form_submission_path(id: @form_submission.id, step_id: prev_step), status: :see_other and return
      else
        redirect_to form_submission_path(id: @form_submission.id, step_id: @step_id), status: :see_other and return
      end
    elsif params[:commit] == 'Save and Exit'
      # Save the current state and redirect to the dashboard
      @navigation.save_state
      redirect_to root_path, notice: 'Your progress has been saved. You can resume later.' and return
    else
      @navigation_state = @navigation.navigation_state(@step_id)
      
      # For residence_history, use the new form_steps view
      if @step_id == 'residence_history'
        redirect_to form_steps_residence_history_path and return
      else
        render "form_submissions/steps/#{@step_id}"
      end
    end
  end
  
  # POST /form/validate_step
  def validate_step
    @form_state = FormStateService.new(@form_submission)
    step_id = params[:step_id]
    values = params[:form_submission]&.to_unsafe_h || {}
    
    validation_result = @form_state.validate_step(step_id, values)
    render json: validation_result
  end
  
  # GET /form/complete
  def complete
    @navigation = @form_submission.navigation
    
    # Reload the form submission to ensure we have the latest data
    @form_submission.reload
    
    # Cache key for completion check
    cache_key = "form_completion:#{@form_submission.id}:#{@form_submission.updated_at.to_i}"
    
    # Try to get completion status from cache
    completion_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      # Check if all available steps are complete
      all_complete = @navigation.available_steps.all? { |step_id| @form_submission.step_complete?(step_id) }
      
      if all_complete
        { complete: true }
      else
        # Find the first incomplete step
        incomplete_step = @navigation.first_incomplete_step
        { complete: false, incomplete_step: incomplete_step || @navigation.available_steps.first }
      end
    end
    
    if completion_data[:complete]
      # Process the completed form submission
      # This could involve creating a Claim record or other processing
      render :complete
    else
      # Redirect to the first incomplete step
      redirect_to form_submission_path(id: @form_submission.id, step_id: completion_data[:incomplete_step])
    end
  end
  
  # GET /form/:id/audit_trail
  def audit_trail
    @step_id = params[:step_id]
    @page = params[:page] || 1
    @per_page = params[:per_page] || 50
    
    # Get audit logs for the form submission
    if @step_id.present?
      @audit_logs = AuditService.get_history(@form_submission, @step_id)
    else
      @audit_logs = AuditService.get_history(@form_submission)
    end
    
    # Paginate the results
    @audit_logs = @audit_logs.page(@page).per(@per_page)
  end
  
  # GET /form/:id/resume
  def resume
    # Resume the form from the saved state
    step_id = @form_submission.resume
    
    # Preload the step data
    @lazy_loader.lazy_load_step(step_id)
    
    # Redirect to the current step
    redirect_to form_submission_path(id: @form_submission.id, step_id: step_id)
  end
  
  # DELETE /form
  def destroy
    @step_id = params[:step_id]
    entry_index = params[:entry_index].to_i
    
    # Get the current entries
    @form_state = FormStateService.new(@form_submission)
    current_values = @form_submission.step_values(@step_id) || {}
    current_entries = current_values['entries'] || []
    
    # Remove the entry at the specified index
    if entry_index < current_entries.length
      current_entries.delete_at(entry_index)
      
      # Update the step state
      new_values = current_values.merge('entries' => current_entries)
      @form_state.update_step(@step_id, new_values, current_user&.id)
    end
    
    # Redirect back to the education step
    redirect_to form_submission_path(id: @form_submission.id, step_id: @step_id), status: :see_other
  end
  
  private
  
  # Set the lazy loader
  def set_lazy_loader
    @lazy_loader = LazyLoadingService.new(@form_submission)
  end
  
  def handle_education_entry(values)
    # Extract education entry fields
    entry = {
      'institution' => values['institution'],
      'degree' => values['degree'],
      'field_of_study' => values['field_of_study'],
      'location' => values['location'],
      'start_date' => values['start_date'],
      'end_date' => values['is_current'] ? nil : values['end_date'],
      'is_current' => values['is_current'] == '1'
    }
    
    # Get current entries directly from the form_submission steps
    current_step = @form_submission.steps['education'] || {}
    current_values = current_step['values'] || {}
    current_entries = current_values['entries'] || []
    
    # Add the new entry
    new_entries = current_entries + [entry]
    
    # Create a new values hash with the updated entries
    new_values = {}
    new_values['entries'] = new_entries
    if values['highest_level'].present?
      new_values['highest_level'] = values['highest_level']
    elsif current_values['highest_level'].present?
      new_values['highest_level'] = current_values['highest_level']
    end
    
    # Update the step state
    @form_state.update_step('education', new_values, current_user&.id)
  end
  
  def check_form_expiration
    # Check if the form has expired
    if @form_submission.expired?
      redirect_to root_path, alert: 'Your form has expired. Please start a new form.' and return
    end
  end
  
  def set_form_submission
    if user_signed_in?
      # For authenticated users, find or create a form submission associated with the user
      @form_submission = current_user.form_submissions.find_by(id: session[:form_submission_id])
      
      if @form_submission.nil?
        @form_submission = current_user.form_submissions.find_or_create_by(id: params[:id])
      end
    else
      # For guests, use session to track the form submission
      
      # First try to find by session_id stored in the session
      if session[:form_submission_id].present?
        @form_submission = FormSubmission.find_by(session_id: session[:form_submission_id])
      end
      
      # If not found by session_id, try by ID parameter
      if @form_submission.nil? && params[:id].present?
        @form_submission = FormSubmission.find_by(id: params[:id])
      end
      
      if @form_submission.nil?
        # If form submission not found or no ID provided, create a new one
        @form_submission = FormSubmission.create(
          session_id: SecureRandom.uuid,
          current_step_id: 'residence_history',
          requirements_config_id: RequirementsConfig.first_or_create.id
        )
        session[:form_submission_id] = @form_submission.session_id
      end
    end
    
    # Ensure requirements_config is set
    if params[:requirements_config_id].present?
      @form_submission.update(requirements_config_id: params[:requirements_config_id])
    elsif @form_submission.requirements_config.nil?
      @form_submission.update(requirements_config: RequirementsConfig.first_or_create)
    end
  end
end
class FormSubmissionsApiController < ApplicationController
  before_action :set_form_submission
  
  # GET /form_submissions_api/:id/state
  def state
    form_state = FormStateService.new(@form_submission)
    render json: {
      form_state: @form_submission.steps,
      navigation_state: form_state.navigation_state,
      requirements: @form_submission.requirements_config
    }
  end
  
  # POST /form_submissions_api/validate_step
  def validate_step
    form_state = FormStateService.new(@form_submission)
    step_id = params[:step_id]
    values = params[:form_submission]&.to_unsafe_h || {}
    
    render json: form_state.validate_step(step_id, values)
  end
  
  # POST /form_submissions_api/move_to_step
  def move_to_step
    form_state = FormStateService.new(@form_submission)
    step_id = params[:step_id]
    
    if form_state.is_step_enabled(step_id)
      form_state.move_to_step(step_id)
      render json: { success: true, current_step_id: @form_submission.current_step_id }
    else
      render json: { success: false, error: 'Step is not enabled' }, status: :unprocessable_entity
    end
  end
  
  # POST /form_submissions_api/add_timeline_entry
  def add_timeline_entry
    form_state = FormStateService.new(@form_submission)
    step_id = params[:step_id]
    entry = params[:entry]&.to_unsafe_h || {}
    
    form_state.add_timeline_entry(step_id, entry)
    render json: { entries: form_state.get_timeline_entries(step_id) }
  end
  
  # POST /form_submissions_api/update_timeline_entry
  def update_timeline_entry
    form_state = FormStateService.new(@form_submission)
    step_id = params[:step_id]
    index = params[:index].to_i
    entry = params[:entry]&.to_unsafe_h || {}
    
    form_state.update_timeline_entry(step_id, index, entry)
    render json: { entries: form_state.get_timeline_entries(step_id) }
  end
  
  # DELETE /form_submissions_api/remove_timeline_entry
  def remove_timeline_entry
    form_state = FormStateService.new(@form_submission)
    step_id = params[:step_id]
    index = params[:index].to_i
    
    form_state.remove_timeline_entry(step_id, index)
    render json: { entries: form_state.get_timeline_entries(step_id) }
  end
  
  # POST /form_submissions_api/submit
  def submit
    form_state = FormStateService.new(@form_submission)
    result = form_state.submit_form
    
    render json: result
  end
  
  private
  
  def set_form_submission
    if user_signed_in?
      @form_submission = current_user.form_submissions.find_by(id: params[:id])
      
      # If form submission not found, create a new one
      if @form_submission.nil?
        @form_submission = current_user.form_submissions.create
      end
    else
      @form_submission = FormSubmission.find_by(id: session[:form_submission_id])
      
      # If form submission not found, create a new one
      if @form_submission.nil?
        session[:form_submission_id] ||= SecureRandom.uuid
        @form_submission = FormSubmission.create(session_id: session[:form_submission_id])
      end
      
      session[:form_submission_id] = @form_submission.id
    end
  end
end
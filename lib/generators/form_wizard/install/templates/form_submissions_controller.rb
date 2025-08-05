# frozen_string_literal: true

# Controller for handling form submissions
class FormSubmissionsController < ApplicationController
  before_action :set_form_submission
  
  # GET /form
  # GET /form/:step_id
  def show
    @step_id = params[:step_id] || @form_submission.current_step_id
    
    # Initialize the form service
    @service = FormWizard::FormSubmissionService.new(@form_submission)
    
    # Get the navigation state
    @navigation_state = @service.navigation_state
    
    # Render the step
    render "form_wizard/steps/#{@step_id}"
  end
  
  # PATCH /form
  def update
    @step_id = params[:step_id]
    
    # Initialize the form service
    @service = FormWizard::FormSubmissionService.new(@form_submission)
    
    # Get form values from params
    values = params[:form_submission]&.to_unsafe_h || {}
    
    # Update the step
    @service.update_step(@step_id, values)
    
    # Handle navigation
    if params[:commit] == 'Next'
      @service.next_step
      redirect_to form_submission_path(step_id: @form_submission.current_step_id)
    elsif params[:commit] == 'Previous'
      @service.previous_step
      redirect_to form_submission_path(step_id: @form_submission.current_step_id)
    elsif params[:commit] == 'Submit'
      result = @service.submit
      
      if result[:success]
        redirect_to complete_form_submission_path
      else
        @navigation_state = @service.navigation_state
        flash.now[:alert] = "Please fix the errors before submitting."
        render "form_wizard/steps/#{@step_id}"
      end
    else
      @navigation_state = @service.navigation_state
      render "form_wizard/steps/#{@step_id}"
    end
  end
  
  # POST /form/validate_step
  def validate_step
    @service = FormWizard::FormSubmissionService.new(@form_submission)
    
    step_id = params[:step_id]
    values = params[:form_submission]&.to_unsafe_h || {}
    
    validation_result = @service.validation.validate_step(step_id, values)
    render json: validation_result
  end
  
  # GET /form/complete
  def complete
    @service = FormWizard::FormSubmissionService.new(@form_submission)
    
    if @service.complete?
      render :complete
    else
      redirect_to form_submission_path
    end
  end
  
  private
  
  def set_form_submission
    if user_signed_in?
      # For authenticated users, find or create a form submission associated with the user
      @form_submission = current_user.form_submissions.find_or_create_by(id: params[:id])
    else
      # For guests, use session to track the form submission
      if session[:form_submission_id].present?
        @form_submission = FormSubmission.find_by(id: session[:form_submission_id])
      end
      
      if @form_submission.nil?
        # If form submission not found or no ID provided, create a new one
        @form_submission = FormSubmission.create
        session[:form_submission_id] = @form_submission.id
      end
    end
  end
end
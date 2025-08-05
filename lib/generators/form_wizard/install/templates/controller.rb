# frozen_string_literal: true

class FormSubmissionsController < ApplicationController
  include FormWizard::Controller
  
  before_action :load_form_submission, only: [:show, :update, :validate_step, :complete]
  
  # GET /form
  def show
    @step = params[:step] || current_step
    @component = FormWizard::WizardComponent.new(
      form_submission: @form_submission,
      step: @step,
      flow: current_flow
    )
    
    render 'form_wizard/show'
  end
  
  # PATCH /form
  def update
    service = FormWizard::FormSubmissionService.new(@form_submission)
    result = service.process_step(
      step: current_step,
      params: form_params,
      flow: current_flow
    )
    
    if result.success?
      if result.next_step
        redirect_to form_submission_path(step: result.next_step)
      else
        redirect_to complete_form_submission_path
      end
    else
      @step = current_step
      @component = FormWizard::WizardComponent.new(
        form_submission: @form_submission,
        step: @step,
        flow: current_flow,
        errors: result.errors
      )
      
      render 'form_wizard/show'
    end
  end
  
  # POST /form/validate_step
  def validate_step
    service = FormWizard::ValidationService.new(@form_submission)
    result = service.validate_step(
      step: params[:step],
      params: form_params,
      flow: current_flow
    )
    
    render json: { valid: result.valid?, errors: result.errors }
  end
  
  # GET /form/complete
  def complete
    @component = FormWizard::CompleteComponent.new(
      form_submission: @form_submission,
      flow: current_flow
    )
    
    render 'form_wizard/complete'
  end
  
  private
  
  def load_form_submission
    @form_submission = FormSubmission.find_or_initialize_by(session_id: session_id)
  end
  
  def session_id
    session[:form_submission_id] ||= SecureRandom.uuid
  end
  
  def current_step
    @form_submission.current_step || current_flow.initial_step
  end
  
  def current_flow
    @current_flow ||= <%= options[:flow_name].camelize %>Flow.new
  end
  
  def form_params
    params.require(:form_submission).permit!
  end
end
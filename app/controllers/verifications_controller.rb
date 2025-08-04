class VerificationsController < ApplicationController
  before_action :set_claim, only: [:show, :step, :update_step, :complete]
  
  # GET /verifications/new
  def new
    # Start a new verification process
    redirect_to verification_path(SecureRandom.hex(10))
  end
  
  # GET /verifications/:id
  def show
    # If claim doesn't exist yet, create it
    unless @claim
      @claim = Claim.create!(
        tracking_id: params[:id],
        submission_date: nil,
        collection_key: params[:collection_key] || "en-EPA-DTB-R5-E5-E-P-W", # Default to full collection
        language: params[:language] || "en"
      )
    end
    
    # Redirect to the first incomplete step
    redirect_to step_verification_path(@claim.tracking_id, step: first_incomplete_step)
  end
  
  # GET /verifications/:id/step/:step
  def step
    @step = params[:step]
    
    # Ensure the step is valid
    unless valid_steps.include?(@step)
      redirect_to step_verification_path(@claim.tracking_id, step: first_incomplete_step)
      return
    end
    
    # Initialize step data if needed
    case @step
    when 'personal_info'
      @claimant = @claim.claimant || @claim.build_claimant
    when 'consents'
      @consents = @claim.consents || @claim.build_consents
    when 'residence_history'
      @residence_history = @claim.residence_history || @claim.build_residence_history
      @residence_entries = @residence_history.residence_entries
      @required_years = @claim.requirements.residence_history_years
    when 'employment_history'
      @employment_history = @claim.employment_history || @claim.build_employment_history
      @employment_entries = @employment_history.employment_entries
      @employment_mode = @claim.requirements.employment_history_mode
      @required_years = @claim.requirements.employment_history_years
      @required_employers = @claim.requirements.employment_history_employers
    when 'education'
      @education = @claim.education || @claim.build_education
      @education_entries = @education.education_entries
    when 'professional_licenses'
      @professional_licenses = @claim.professional_licenses || @claim.build_professional_licenses
      @professional_license_entries = @professional_licenses.professional_license_entries
    when 'signature'
      @signature = @claim.signature || @claim.build_signature
    end
    
    # Render the appropriate step template
    render "verifications/steps/#{@step}"
  end
  
  # POST /verifications/:id/step/:step
  def update_step
    @step = params[:step]
    
    # Process the step data
    case @step
    when 'personal_info'
      @claim.build_claimant unless @claim.claimant
      if @claim.claimant.update(claimant_params.merge(completed_at: Time.current))
        redirect_to next_step_path
      else
        render "verifications/steps/#{@step}"
      end
    when 'consents'
      @claim.build_consents unless @claim.consents
      if @claim.consents.update(consents_params.merge(completed_at: Time.current))
        redirect_to next_step_path
      else
        render "verifications/steps/#{@step}"
      end
    when 'residence_history'
      process_residence_history
    when 'employment_history'
      process_employment_history
    when 'education'
      process_education
    when 'professional_licenses'
      process_professional_licenses
    when 'signature'
      @claim.build_signature unless @claim.signature
      if @claim.signature.update(signature_params.merge(date: Time.current))
        # Complete the verification
        @claim.update(submission_date: Time.current)
        redirect_to complete_verification_path(@claim.tracking_id)
      else
        render "verifications/steps/#{@step}"
      end
    else
      redirect_to step_verification_path(@claim.tracking_id, step: first_incomplete_step)
    end
  end
  
  # GET /verifications/:id/complete
  def complete
    # Ensure the verification is complete
    unless @claim.submission_date.present?
      redirect_to step_verification_path(@claim.tracking_id, step: first_incomplete_step)
      return
    end
    
    # Render the completion page
    render "verifications/complete"
  end
  
  private
  
  def set_claim
    @claim = Claim.find_by(tracking_id: params[:id])
  end
  
  def valid_steps
    steps = ['personal_info']
    
    # Only include steps that are required based on the collection key
    if @claim.requirements.consents_required?('driver_license') || 
       @claim.requirements.consents_required?('drug_test') || 
       @claim.requirements.consents_required?('biometric')
      steps << 'consents'
    end
    
    if @claim.requirements.verification_step_enabled?('residence_history')
      steps << 'residence_history'
    end
    
    if @claim.requirements.verification_step_enabled?('employment_history')
      steps << 'employment_history'
    end
    
    if @claim.requirements.verification_step_enabled?('education')
      steps << 'education'
    end
    
    if @claim.requirements.verification_step_enabled?('professional_license')
      steps << 'professional_licenses'
    end
    
    # Signature is always required
    steps << 'signature'
    
    steps
  end
  
  def first_incomplete_step
    # Return the first step that is not complete
    valid_steps.each do |step|
      case step
      when 'personal_info'
        return step unless @claim.claimant&.complete?
      when 'consents'
        return step unless @claim.consents&.complete?
      when 'residence_history'
        return step unless @claim.residence_history&.complete?
      when 'employment_history'
        return step unless @claim.employment_history&.complete?
      when 'education'
        return step unless @claim.education&.complete?
      when 'professional_licenses'
        return step unless @claim.professional_licenses&.complete?
      when 'signature'
        return step unless @claim.signature.present?
      end
    end
    
    # If all steps are complete, return the signature step
    'signature'
  end
  
  def next_step_path
    current_index = valid_steps.index(@step)
    next_step = valid_steps[current_index + 1]
    step_verification_path(@claim.tracking_id, step: next_step)
  end
  
  def process_residence_history
    @claim.build_residence_history unless @claim.residence_history
    
    if params[:residence_entry].present?
      # Add a new residence entry
      residence_entry = @claim.residence_history.residence_entries.build(residence_entry_params)
      if residence_entry.save
        @claim.residence_history.update_total_years!
        redirect_to step_verification_path(@claim.tracking_id, step: 'residence_history')
      else
        @residence_history = @claim.residence_history
        @residence_entries = @residence_history.residence_entries
        @required_years = @claim.requirements.residence_history_years
        render "verifications/steps/residence_history"
      end
    elsif params[:complete_step].present?
      # Complete the step
      if @claim.residence_history.update(completed_at: Time.current)
        redirect_to next_step_path
      else
        @residence_history = @claim.residence_history
        @residence_entries = @residence_history.residence_entries
        @required_years = @claim.requirements.residence_history_years
        render "verifications/steps/residence_history"
      end
    else
      redirect_to step_verification_path(@claim.tracking_id, step: 'residence_history')
    end
  end
  
  def process_employment_history
    @claim.build_employment_history unless @claim.employment_history
    
    if params[:employment_entry].present?
      # Add a new employment entry
      employment_entry = @claim.employment_history.employment_entries.build(employment_entry_params)
      if employment_entry.save
        @claim.employment_history.update_total_years!
        redirect_to step_verification_path(@claim.tracking_id, step: 'employment_history')
      else
        @employment_history = @claim.employment_history
        @employment_entries = @employment_history.employment_entries
        @employment_mode = @claim.requirements.employment_history_mode
        @required_years = @claim.requirements.employment_history_years
        @required_employers = @claim.requirements.employment_history_employers
        render "verifications/steps/employment_history"
      end
    elsif params[:complete_step].present?
      # Complete the step
      if @claim.employment_history.update(completed_at: Time.current)
        redirect_to next_step_path
      else
        @employment_history = @claim.employment_history
        @employment_entries = @employment_history.employment_entries
        @employment_mode = @claim.requirements.employment_history_mode
        @required_years = @claim.requirements.employment_history_years
        @required_employers = @claim.requirements.employment_history_employers
        render "verifications/steps/employment_history"
      end
    else
      redirect_to step_verification_path(@claim.tracking_id, step: 'employment_history')
    end
  end
  
  def process_education
    @claim.build_education unless @claim.education
    
    if params[:education].present?
      # Update education info
      if @claim.education.update(education_params)
        redirect_to step_verification_path(@claim.tracking_id, step: 'education')
      else
        @education = @claim.education
        @education_entries = @education.education_entries
        render "verifications/steps/education"
      end
    elsif params[:education_entry].present?
      # Add a new education entry
      education_entry = @claim.education.education_entries.build(education_entry_params)
      if education_entry.save
        redirect_to step_verification_path(@claim.tracking_id, step: 'education')
      else
        @education = @claim.education
        @education_entries = @education.education_entries
        render "verifications/steps/education"
      end
    elsif params[:complete_step].present?
      # Complete the step
      if @claim.education.update(completed_at: Time.current)
        redirect_to next_step_path
      else
        @education = @claim.education
        @education_entries = @education.education_entries
        render "verifications/steps/education"
      end
    else
      redirect_to step_verification_path(@claim.tracking_id, step: 'education')
    end
  end
  
  def process_professional_licenses
    @claim.build_professional_licenses unless @claim.professional_licenses
    
    if params[:professional_license_entry].present?
      # Add a new professional license entry
      license_entry = @claim.professional_licenses.professional_license_entries.build(professional_license_entry_params)
      if license_entry.save
        redirect_to step_verification_path(@claim.tracking_id, step: 'professional_licenses')
      else
        @professional_licenses = @claim.professional_licenses
        @professional_license_entries = @professional_licenses.professional_license_entries
        render "verifications/steps/professional_licenses"
      end
    elsif params[:complete_step].present?
      # Complete the step
      if @claim.professional_licenses.update(completed_at: Time.current)
        redirect_to next_step_path
      else
        @professional_licenses = @claim.professional_licenses
        @professional_license_entries = @professional_licenses.professional_license_entries
        render "verifications/steps/professional_licenses"
      end
    else
      redirect_to step_verification_path(@claim.tracking_id, step: 'professional_licenses')
    end
  end
  
  # Strong parameters
  
  def claimant_params
    params.require(:claimant).permit(:full_name, :email, :phone, :date_of_birth, :ssn)
  end
  
  def consents_params
    # Process each consent type
    result = {}
    
    if params[:driver_license_consent].present?
      result[:driver_license] = {
        granted: params[:driver_license_consent] == '1',
        date: Time.current.iso8601,
        notes: params[:driver_license_notes]
      }
    end
    
    if params[:drug_test_consent].present?
      result[:drug_test] = {
        granted: params[:drug_test_consent] == '1',
        date: Time.current.iso8601,
        notes: params[:drug_test_notes]
      }
    end
    
    if params[:biometric_consent].present?
      result[:biometric] = {
        granted: params[:biometric_consent] == '1',
        date: Time.current.iso8601,
        notes: params[:biometric_notes]
      }
    end
    
    result
  end
  
  def residence_entry_params
    params.require(:residence_entry).permit(
      :country, :address, :city, :state_province, :zip_postal, 
      :start_date, :end_date, :is_current
    )
  end
  
  def employment_entry_params
    params.require(:employment_entry).permit(
      :type, :company, :position, :country, :city, :state_province, 
      :description, :contact_name, :contact_type, :contact_email, 
      :contact_phone, :contact_preferred_method, :no_contact_attestation, 
      :contact_explanation, :start_date, :end_date, :is_current
    )
  end
  
  def education_params
    params.require(:education).permit(:highest_level)
  end
  
  def education_entry_params
    params.require(:education_entry).permit(
      :institution, :degree, :field_of_study, :start_date, 
      :end_date, :is_current, :description, :location
    )
  end
  
  def professional_license_entry_params
    params.require(:professional_license_entry).permit(
      :license_type, :license_number, :issuing_authority, :issue_date, 
      :expiration_date, :is_active, :state, :country, :description, 
      :start_date, :end_date, :is_current
    )
  end
  
  def signature_params
    params.require(:signature).permit(:data)
  end
end
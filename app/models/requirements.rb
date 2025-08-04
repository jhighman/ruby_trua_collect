class Requirements < ApplicationRecord
  # Attributes
  # - consents_required: jsonb - Stores which consents are required
  # - verification_steps: jsonb - Stores verification step configuration

  # Relationships
  belongs_to :claim

  # Validations
  validates :consents_required, presence: true
  validates :verification_steps, presence: true

  # Methods
  def consents_required?(type)
    consents_required&.dig(type.to_s) == true
  end

  def verification_step_enabled?(step)
    verification_steps&.dig(step.to_s, 'enabled') == true
  end

  def residence_history_years
    verification_steps&.dig('residence_history', 'years').to_i
  end

  def employment_history_mode
    verification_steps&.dig('employment_history', 'mode')
  end

  def employment_history_years
    verification_steps&.dig('employment_history', 'years').to_i
  end

  def employment_history_employers
    verification_steps&.dig('employment_history', 'employers').to_i
  end

  def to_collection_key_parser_requirements
    # Create a Requirements object from the CollectionKeyParser module
    requirements = CollectionKeyParser::Requirements.new
    
    # Set language
    requirements.language = claim.language
    
    # Set consents required
    requirements.consents_required.driver_license = consents_required?('driver_license')
    requirements.consents_required.drug_test = consents_required?('drug_test')
    requirements.consents_required.biometric = consents_required?('biometric')
    
    # Set verification steps
    requirements.verification_steps.personal_info.enabled = verification_step_enabled?('personal_info')
    requirements.verification_steps.personal_info.modes.email = verification_steps&.dig('personal_info', 'modes', 'email') == true
    requirements.verification_steps.personal_info.modes.phone = verification_steps&.dig('personal_info', 'modes', 'phone') == true
    requirements.verification_steps.personal_info.modes.full_name = verification_steps&.dig('personal_info', 'modes', 'full_name') == true
    requirements.verification_steps.personal_info.modes.name_alias = verification_steps&.dig('personal_info', 'modes', 'name_alias') == true
    
    requirements.verification_steps.residence_history.enabled = verification_step_enabled?('residence_history')
    requirements.verification_steps.residence_history.years = residence_history_years
    
    requirements.verification_steps.employment_history.enabled = verification_step_enabled?('employment_history')
    requirements.verification_steps.employment_history.mode = employment_history_mode
    if employment_history_mode == 'years'
      requirements.verification_steps.employment_history.modes.years = employment_history_years
    else
      requirements.verification_steps.employment_history.modes.employers = employment_history_employers
    end
    
    requirements.verification_steps.education.enabled = verification_step_enabled?('education')
    requirements.verification_steps.professional_license.enabled = verification_step_enabled?('professional_license')
    
    # Set signature
    requirements.signature.required = verification_step_enabled?('signature')
    requirements.signature.mode = verification_steps&.dig('signature', 'mode')
    
    requirements
  end
end
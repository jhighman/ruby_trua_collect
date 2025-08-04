class RequirementsConfig < ApplicationRecord
  # Attributes
  # - consents_required: jsonb - Stores which consents are required
  # - verification_steps: jsonb - Stores verification step configuration
  # - signature: jsonb - Stores signature requirements

  # Relationships
  has_many :form_submissions

  # Validations
  validates :consents_required, :verification_steps, :signature, presence: true

  # Methods
  def consents_required?(type)
    consents_required&.dig(type.to_s) == true
  end

  def verification_step_enabled?(step)
    verification_steps&.dig(step.to_s, 'enabled') == true
  end

  def residence_history_years
    verification_steps&.dig('residenceHistory', 'years').to_i
  end

  def employment_history_years
    verification_steps&.dig('employmentHistory', 'years').to_i
  end

  def signature_required?
    signature&.dig('required') == true
  end

  def signature_mode
    signature&.dig('mode')
  end
end
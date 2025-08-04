class Claim < ApplicationRecord
  # Attributes
  # - tracking_id: string - Unique identifier for the verification request
  # - submission_date: datetime - When the claim was submitted
  # - collection_key: string - Unique key for the collection session
  # - language: string - Language code for the submission

  # Relationships
  has_one :claimant, dependent: :destroy
  has_one :requirements, dependent: :destroy
  has_one :consents, dependent: :destroy
  has_one :residence_history, dependent: :destroy
  has_one :employment_history, dependent: :destroy
  has_one :education, dependent: :destroy
  has_one :professional_licenses, dependent: :destroy
  has_one :signature, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :claimant
  
  # Validations
  validates :tracking_id, presence: true, uniqueness: true
  validates :submission_date, presence: true
  validates :collection_key, presence: true
  validates :language, presence: true

  # Parse collection key and set requirements
  before_validation :set_requirements_from_collection_key, on: :create

  # Methods
  def set_requirements_from_collection_key
    return unless collection_key.present?
    
    # Use the CollectionKeyParser to get requirements
    parsed_requirements = CollectionKeyParser.get_requirements(collection_key)
    
    # Create Requirements record
    build_requirements(
      consents_required: {
        driver_license: parsed_requirements.consents_required.driver_license,
        drug_test: parsed_requirements.consents_required.drug_test,
        biometric: parsed_requirements.consents_required.biometric
      },
      verification_steps: {
        education_enabled: parsed_requirements.verification_steps.education.enabled,
        professional_license_enabled: parsed_requirements.verification_steps.professional_license.enabled,
        residence_history_enabled: parsed_requirements.verification_steps.residence_history.enabled,
        residence_history_years: parsed_requirements.verification_steps.residence_history.years,
        employment_history_enabled: parsed_requirements.verification_steps.employment_history.enabled,
        employment_history_mode: parsed_requirements.verification_steps.employment_history.mode,
        employment_history_years: parsed_requirements.verification_steps.employment_history.modes.years,
        employment_history_employers: parsed_requirements.verification_steps.employment_history.modes.employers
      }
    )
  end

  # Generate a JSON document for the claim
  def to_json_document
    {
      metadata: {
        trackingId: tracking_id,
        submissionDate: submission_date.iso8601,
        version: "1.0"
      },
      timeline: generate_timeline,
      personalInfo: claimant&.to_json_document,
      residenceHistory: residence_history&.entries&.map(&:to_json_document),
      employmentHistory: employment_history&.entries&.map(&:to_json_document),
      education: education&.to_json_document,
      professionalLicenses: professional_licenses&.entries&.map(&:to_json_document),
      consents: consents&.to_json_document,
      signature: signature&.to_json_document
    }
  end

  private

  def generate_timeline
    timeline = {
      startDate: calculate_start_date,
      endDate: submission_date.iso8601
    }

    if employment_history&.entries&.any?
      timeline[:employmentTimeline] = {
        entries: employment_history.entries.map(&:to_json_document),
        startDate: employment_history.entries.map(&:start_date).min.iso8601,
        endDate: employment_history.entries.map { |e| e.end_date || submission_date }.max.iso8601
      }
    end

    if residence_history&.entries&.any?
      timeline[:residenceTimeline] = {
        entries: residence_history.entries.map(&:to_json_document),
        startDate: residence_history.entries.map(&:start_date).min.iso8601,
        endDate: residence_history.entries.map { |e| e.end_date || submission_date }.max.iso8601
      }
    end

    if education&.entries&.any?
      timeline[:educationTimeline] = {
        entries: education.entries.map(&:to_json_document),
        startDate: education.entries.map(&:start_date).min.iso8601,
        endDate: education.entries.map { |e| e.end_date || submission_date }.max.iso8601
      }
    end

    if professional_licenses&.entries&.any?
      timeline[:licensesTimeline] = {
        entries: professional_licenses.entries.map(&:to_json_document),
        startDate: professional_licenses.entries.map(&:start_date).min.iso8601,
        endDate: professional_licenses.entries.map { |e| e.end_date || submission_date }.max.iso8601
      }
    end

    timeline
  end

  def calculate_start_date
    dates = []
    dates << employment_history&.entries&.map(&:start_date)&.min
    dates << residence_history&.entries&.map(&:start_date)&.min
    dates << education&.entries&.map(&:start_date)&.min
    dates << professional_licenses&.entries&.map(&:start_date)&.min
    
    dates.compact.min&.iso8601 || submission_date.iso8601
  end
end
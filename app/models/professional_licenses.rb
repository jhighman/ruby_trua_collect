class ProfessionalLicenses < ApplicationRecord
  # Attributes
  # - completed_at: datetime - When this section was completed

  # Relationships
  belongs_to :claim
  has_many :professional_license_entries, dependent: :destroy

  # Validations
  validate :has_entries, if: -> { claim&.requirements&.verification_step_enabled?('professional_license') }

  # Methods
  def complete!
    update(completed_at: Time.current)
  end

  def complete?
    completed_at.present?
  end

  def to_json_document
    {
      entries: professional_license_entries.map(&:to_json_document),
      completedAt: completed_at&.iso8601
    }
  end

  private

  def has_entries
    if professional_license_entries.empty?
      errors.add(:professional_license_entries, "must include at least one professional license entry")
    end
  end
end
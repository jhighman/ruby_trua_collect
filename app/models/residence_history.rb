class ResidenceHistory < ApplicationRecord
  # Attributes
  # - total_years: float - Total years covered by residence entries
  # - completed_at: datetime - When this section was completed

  # Relationships
  belongs_to :claim
  has_many :residence_entries, dependent: :destroy

  # Validations
  validate :required_years_covered, if: -> { claim&.requirements&.verification_step_enabled?('residence_history') }

  # Methods
  def complete!
    update(completed_at: Time.current)
  end

  def complete?
    completed_at.present?
  end

  def calculate_total_years
    entries.sum(&:duration_years)
  end

  def update_total_years!
    update(total_years: calculate_total_years)
  end

  def to_json_document
    {
      entries: entries.map(&:to_json_document),
      totalYears: total_years,
      completedAt: completed_at&.iso8601
    }
  end

  private

  def required_years_covered
    return unless claim&.requirements

    required_years = claim.requirements.residence_history_years
    if total_years.to_f < required_years
      errors.add(:total_years, "must cover at least #{required_years} years of history")
    end
  end
end
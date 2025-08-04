class Education < ApplicationRecord
  # Attributes
  # - highest_level: string - Highest level of education achieved
  # - completed_at: datetime - When this section was completed

  # Relationships
  belongs_to :claim
  has_many :education_entries, dependent: :destroy

  # Validations
  validates :highest_level, presence: true, if: -> { claim&.requirements&.verification_step_enabled?('education') }
  validate :has_entries, if: -> { claim&.requirements&.verification_step_enabled?('education') }

  # Methods
  def complete!
    update(completed_at: Time.current)
  end

  def complete?
    completed_at.present?
  end

  def to_json_document
    {
      highestLevel: highest_level,
      timelineEntries: education_entries.map(&:to_json_document),
      completedAt: completed_at&.iso8601
    }
  end

  private

  def has_entries
    if education_entries.empty?
      errors.add(:education_entries, "must include at least one education entry")
    end
  end
end
class EducationEntry < ApplicationRecord
  # Attributes
  # - institution: string - Name of the educational institution
  # - degree: string - Degree obtained
  # - field_of_study: string - Field of study
  # - start_date: date - When the education began
  # - end_date: date - When the education ended
  # - is_current: boolean - Whether this is the current education
  # - description: text - Additional details about the education
  # - location: string - Location of the institution

  # Relationships
  belongs_to :education

  # Validations
  validates :institution, presence: true
  validates :degree, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :current_education_has_no_end_date
  validate :non_current_education_has_end_date

  # Methods
  def to_json_document
    {
      id: id,
      institution: institution,
      degree: degree,
      fieldOfStudy: field_of_study,
      startDate: start_date&.iso8601,
      endDate: end_date&.iso8601,
      isCurrent: is_current,
      description: description,
      location: location
    }
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def current_education_has_no_end_date
    if is_current? && end_date.present?
      errors.add(:end_date, "must be blank for current education")
    end
  end

  def non_current_education_has_end_date
    if !is_current? && end_date.blank?
      errors.add(:end_date, "must be present for non-current education")
    end
  end
end
class ProfessionalLicenseEntry < ApplicationRecord
  # Attributes
  # - license_type: string - Type of the license
  # - license_number: string - License identifier or number
  # - issuing_authority: string - Organization that issued the license
  # - issue_date: date - When the license was issued
  # - expiration_date: date - When the license expires
  # - is_active: boolean - Whether the license is currently active
  # - state: string - State or province where the license is valid
  # - country: string - Country where the license is valid
  # - description: text - Additional details about the license
  # - start_date: date - When the license became valid
  # - end_date: date - When the license expires
  # - is_current: boolean - Whether this is a current license

  # Relationships
  belongs_to :professional_licenses

  # Validations
  validates :license_type, presence: true
  validates :license_number, presence: true
  validates :issuing_authority, presence: true
  validates :issue_date, presence: true
  validates :expiration_date, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :current_license_has_no_end_date
  validate :non_current_license_has_end_date
  validate :expiration_date_consistent_with_end_date

  # Methods
  def to_json_document
    {
      id: id,
      licenseType: license_type,
      licenseNumber: license_number,
      issuingAuthority: issuing_authority,
      issueDate: issue_date&.iso8601,
      expirationDate: expiration_date&.iso8601,
      isActive: is_active,
      state: state,
      country: country,
      description: description,
      startDate: start_date&.iso8601,
      endDate: end_date&.iso8601,
      isCurrent: is_current
    }
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def current_license_has_no_end_date
    if is_current? && end_date.present?
      errors.add(:end_date, "must be blank for current license")
    end
  end

  def non_current_license_has_end_date
    if !is_current? && end_date.blank?
      errors.add(:end_date, "must be present for non-current license")
    end
  end

  def expiration_date_consistent_with_end_date
    return if expiration_date.blank? || end_date.blank?

    if is_current? && !is_active?
      errors.add(:is_current, "cannot be true if license is not active")
    end

    if expiration_date != end_date && !is_current?
      errors.add(:expiration_date, "must match end date for non-current licenses")
    end
  end
end
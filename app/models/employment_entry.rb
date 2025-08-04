class EmploymentEntry < ApplicationRecord
  # Attributes
  # - type: string - Type of entry (Job, Education, Unemployed, Other)
  # - company: string - Company or organization name
  # - position: string - Position or title
  # - country: string - Country
  # - city: string - City
  # - state_province: string - State, province, or region
  # - description: text - Additional details about the period
  # - contact_name: string - Name of reference contact
  # - contact_type: string - Type of contact (Manager, HR, Colleague, Other)
  # - contact_email: string - Email of reference contact
  # - contact_phone: string - Phone number of reference contact
  # - contact_preferred_method: string - Preferred contact method (Email, Phone)
  # - no_contact_attestation: boolean - Whether the candidate attests that the employer cannot be contacted
  # - contact_explanation: text - Explanation for why the employer cannot be contacted
  # - start_date: date - When the period began
  # - end_date: date - When the period ended (null if current)
  # - is_current: boolean - Whether this is the current position
  # - duration_years: float - Duration of employment in years

  # Relationships
  belongs_to :employment_history

  # Validations
  validates :company, presence: true
  validates :position, presence: true
  validates :country, presence: true
  validates :city, presence: true
  validates :state_province, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :current_employment_has_no_end_date
  validate :non_current_employment_has_end_date
  validate :contact_info_or_attestation

  # Callbacks
  before_save :calculate_duration
  after_save :update_employment_history_total_years
  after_destroy :update_employment_history_total_years

  # Methods
  def to_json_document
    {
      type: type,
      company: company,
      position: position,
      country: country,
      city: city,
      state_province: state_province,
      description: description,
      contact_name: contact_name,
      contact_type: contact_type,
      contact_email: contact_email,
      contact_phone: contact_phone,
      contact_preferred_method: contact_preferred_method,
      no_contact_attestation: no_contact_attestation,
      contact_explanation: contact_explanation,
      start_date: start_date&.iso8601,
      end_date: end_date&.iso8601,
      is_current: is_current,
      duration_years: duration_years
    }
  end

  private

  def calculate_duration
    if start_date.present?
      end_date_for_calculation = end_date.presence || Time.current.to_date
      self.duration_years = ((end_date_for_calculation - start_date).to_f / 365.25).round(2)
    else
      self.duration_years = 0
    end
  end

  def update_employment_history_total_years
    employment_history.update_total_years!
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def current_employment_has_no_end_date
    if is_current? && end_date.present?
      errors.add(:end_date, "must be blank for current employment")
    end
  end

  def non_current_employment_has_end_date
    if !is_current? && end_date.blank?
      errors.add(:end_date, "must be present for non-current employment")
    end
  end

  def contact_info_or_attestation
    if no_contact_attestation?
      if contact_explanation.blank?
        errors.add(:contact_explanation, "must be provided when employer cannot be contacted")
      end
    else
      if contact_name.blank? || contact_type.blank? || (contact_email.blank? && contact_phone.blank?)
        errors.add(:contact_name, "and contact information must be provided unless no-contact attestation is checked")
      end
    end
  end
end
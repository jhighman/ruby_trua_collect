class ResidenceEntry < ApplicationRecord
  # Attributes
  # - country: string - Country
  # - address: string - Street address
  # - city: string - City
  # - state_province: string - State, province, or region
  # - zip_postal: string - ZIP or postal code
  # - start_date: date - When the candidate began residing at this address
  # - end_date: date - When the candidate stopped residing at this address (null if current)
  # - is_current: boolean - Whether this is the current residence
  # - duration_years: float - Duration of residence in years

  # Relationships
  belongs_to :residence_history

  # Validations
  validates :country, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state_province, presence: true
  validates :zip_postal, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :current_residence_has_no_end_date
  validate :non_current_residence_has_end_date

  # Callbacks
  before_save :calculate_duration
  after_save :update_residence_history_total_years
  after_destroy :update_residence_history_total_years

  # Methods
  def to_json_document
    {
      country: country,
      address: address,
      city: city,
      state_province: state_province,
      zip_postal: zip_postal,
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

  def update_residence_history_total_years
    residence_history.update_total_years!
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def current_residence_has_no_end_date
    if is_current? && end_date.present?
      errors.add(:end_date, "must be blank for current residence")
    end
  end

  def non_current_residence_has_end_date
    if !is_current? && end_date.blank?
      errors.add(:end_date, "must be present for non-current residence")
    end
  end
end
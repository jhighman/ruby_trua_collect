class TimelineEntry
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :start_date, :end_date, :is_current, 
                :license_type, :license_number, :issuing_authority,
                :institution, :degree, :field_of_study, :location,
                :company, :position, :country, :city, :state_province,
                :address, :zip_postal

  validates :start_date, presence: true
  validates :end_date, presence: true, unless: :is_current
  
  # Professional license validations
  validates :license_type, :license_number, :issuing_authority, 
            presence: true, if: :professional_license?
  
  # Calculate duration in years
  def duration_years
    return 0 unless start_date.present?
    
    end_date_value = is_current ? Date.today : end_date
    return 0 unless end_date_value.present?
    
    ((end_date_value - start_date).to_f / 365.25).round(2)
  end
  
  private
  
  def professional_license?
    license_type.present? || license_number.present? || issuing_authority.present?
  end
end
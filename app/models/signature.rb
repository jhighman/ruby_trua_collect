class Signature < ApplicationRecord
  # Attributes
  # - data: text - Base64-encoded PNG image of the signature
  # - date: datetime - When the signature was created

  # Relationships
  belongs_to :claim

  # Validations
  validates :data, presence: true
  validates :date, presence: true

  # Methods
  def to_json_document
    {
      signatureImage: data,
      signatureDate: date&.iso8601,
      confirmation: true
    }
  end

  def base64_valid?
    # Check if the data is a valid Base64-encoded PNG image
    return false unless data.present?
    
    # Check if it starts with the data URI scheme for PNG
    return false unless data.start_with?('data:image/png;base64,')
    
    # Extract the Base64 part
    base64_data = data.sub(/^data:image\/png;base64,/, '')
    
    # Check if it's valid Base64
    begin
      Base64.strict_decode64(base64_data)
      true
    rescue ArgumentError
      false
    end
  end
end
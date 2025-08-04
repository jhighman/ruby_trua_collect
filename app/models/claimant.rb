class Claimant < ApplicationRecord
  # Attributes
  # - full_name: string - The candidate's full name
  # - email: string - The candidate's email address
  # - phone: string - The candidate's phone number
  # - date_of_birth: date - The candidate's date of birth
  # - ssn: string - The candidate's Social Security Number (encrypted)
  # - completed_at: datetime - When this section was completed

  # Relationships
  belongs_to :claim

  # Validations
  validates :full_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :date_of_birth, presence: true
  validates :ssn,
    presence: true,
    format: { with: /\A\d{3}-\d{2}-\d{4}\z/, message: "must be in format XXX-XX-XXXX" },
    if: -> { claim&.requirements&.verification_steps&.dig(:personal_info, :ssn_required) }
  validates :phone, presence: true, if: -> { claim&.requirements&.verification_steps&.dig(:personal_info, :phone_required) }

  # Methods
  def complete!
    update(completed_at: Time.current)
  end

  def complete?
    completed_at.present?
  end

  def to_json_document
    {
      fullName: full_name,
      email: email,
      phone: phone,
      dateOfBirth: date_of_birth&.iso8601,
      ssn: ssn,
      completedAt: completed_at&.iso8601
    }
  end
end
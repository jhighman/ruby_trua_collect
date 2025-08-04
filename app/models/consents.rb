class Consents < ApplicationRecord
  # Attributes
  # - driver_license: jsonb - Driver's license consent record
  # - drug_test: jsonb - Drug test consent record
  # - biometric: jsonb - Biometric consent record
  # - completed_at: datetime - When this section was completed

  # Relationships
  belongs_to :claim

  # Validations
  validate :required_consents_granted

  # Methods
  def complete!
    update(completed_at: Time.current)
  end

  def complete?
    completed_at.present?
  end

  def consent_granted?(type)
    send(type)&.dig('granted') == true
  end

  def consent_date(type)
    send(type)&.dig('date')
  end

  def consent_notes(type)
    send(type)&.dig('notes')
  end

  def grant_consent!(type, notes = nil)
    update(
      type => {
        'granted' => true,
        'date' => Time.current.iso8601,
        'notes' => notes
      }
    )
  end

  def revoke_consent!(type, notes = nil)
    update(
      type => {
        'granted' => false,
        'date' => Time.current.iso8601,
        'notes' => notes
      }
    )
  end

  def to_json_document
    {
      driverLicense: driver_license ? driver_license['granted'] : nil,
      drugTest: drug_test ? drug_test['granted'] : nil,
      biometric: biometric ? biometric['granted'] : nil,
      consentDate: completed_at&.iso8601
    }
  end

  private

  def required_consents_granted
    return unless claim&.requirements

    if claim.requirements.consents_required?('driver_license') && !consent_granted?('driver_license')
      errors.add(:driver_license, "consent is required")
    end

    if claim.requirements.consents_required?('drug_test') && !consent_granted?('drug_test')
      errors.add(:drug_test, "consent is required")
    end

    if claim.requirements.consents_required?('biometric') && !consent_granted?('biometric')
      errors.add(:biometric, "consent is required")
    end
  end
end
class FormConfig
  STEPS = [
    { id: 'personal_info', fields: [
      { id: 'name', label: 'Name', required: true, type: 'string' },
      { id: 'email', label: 'Email', required: true, type: 'email', validation: [{ type: 'pattern', value: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, message: 'Invalid email' }] }
    ] },
    { id: 'education', fields: [
      { id: 'school', label: 'School', required: false, type: 'string' },
      { id: 'degree', label: 'Degree', required: false, type: 'string' },
      { id: 'highest_level', label: 'Highest Level', required: true, type: 'select', options: ['high_school', 'college', 'masters', 'doctorate'] },
      { id: 'entries', label: 'Education History', required: false, type: 'array' }
    ] },
    { id: 'residence_history', fields: [{ id: 'entries', label: 'Residence History', required: true, type: 'array' }] },
    { id: 'employment_history', fields: [{ id: 'entries', label: 'Employment History', required: true, type: 'array' }] },
    { id: 'professional_licenses', fields: [{ id: 'entries', label: 'Licenses', required: false, type: 'array', fields: [
      { id: 'license_type', label: 'License Type', required: true, type: 'string' },
      { id: 'license_number', label: 'License Number', required: true, type: 'string' },
      { id: 'issuing_authority', label: 'Issuing Authority', required: true, type: 'string' }
    ] }] },
    { id: 'consents', fields: [
      { id: 'driver_license_consent', label: 'Driver License Consent', type: 'boolean', required: false },
      { id: 'drug_test_consent', label: 'Drug Test Consent', type: 'boolean', required: false },
      { id: 'biometric_consent', label: 'Biometric Consent', type: 'boolean', required: false }
    ] },
    { id: 'signature', fields: [
      { id: 'signature', label: 'Signature', required: true, type: 'string' },
      { id: 'confirmation', label: 'Confirmation', required: true, type: 'boolean' }
    ] }
  ].freeze

  def self.find_step(step_id)
    STEPS.find { |step| step[:id] == step_id }
  end

  def self.step_ids
    STEPS.map { |step| step[:id] }
  end

  def self.update_step_config(step_id, config)
    step = find_step(step_id)
    return false unless step

    # Create a deep copy of the step to avoid modifying the frozen constant
    updated_step = Marshal.load(Marshal.dump(step))
    
    # Update the step configuration
    config.each do |key, value|
      updated_step[key] = value
    end
    
    # Return the updated step configuration
    updated_step
  end
end
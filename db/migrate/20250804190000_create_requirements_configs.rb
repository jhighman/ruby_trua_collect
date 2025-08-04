class CreateRequirementsConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :requirements_configs do |t|
      t.json :consents_required, default: { driver_license: false, drug_test: false, biometric: false }
      t.json :verification_steps, default: {
        personalInfo: { enabled: true },
        residenceHistory: { enabled: false, years: 3 },
        employmentHistory: { enabled: false },
        education: { enabled: false },
        professionalLicense: { enabled: false }
      }
      t.json :signature, default: { required: true, mode: 'standard' }
      t.timestamps
    end
  end
end
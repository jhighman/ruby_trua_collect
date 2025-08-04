require 'rails_helper'

RSpec.describe FormStateService do
  let(:requirements_config) do
    RequirementsConfig.create(
      consents_required: {
        'driver_license' => true,
        'drug_test' => false,
        'biometric' => true
      },
      verification_steps: {
        'personalInfo' => { 'enabled' => true },
        'residenceHistory' => { 'enabled' => true, 'years' => 3 },
        'employmentHistory' => { 'enabled' => false },
        'education' => { 'enabled' => true },
        'professionalLicense' => { 'enabled' => false }
      },
      signature: {
        'required' => true,
        'mode' => 'standard'
      }
    )
  end

  let(:form_submission) do
    FormSubmission.create(requirements_config: requirements_config, session_id: 'test-session')
  end

  let(:service) { FormStateService.new(form_submission) }

  describe '#is_step_enabled' do
    it 'returns true for enabled steps' do
      expect(service.is_step_enabled('personal_info')).to be true
      expect(service.is_step_enabled('residence_history')).to be true
      expect(service.is_step_enabled('education')).to be true
      expect(service.is_step_enabled('signature')).to be true
      expect(service.is_step_enabled('consents')).to be true
    end

    it 'returns false for disabled steps' do
      expect(service.is_step_enabled('employment_history')).to be false
      expect(service.is_step_enabled('professional_licenses')).to be false
    end
  end

  describe '#available_steps' do
    it 'returns only enabled steps' do
      available_steps = service.available_steps
      expect(available_steps).to include('personal_info', 'residence_history', 'education', 'signature', 'consents')
      expect(available_steps).not_to include('employment_history', 'professional_licenses')
    end
  end
end
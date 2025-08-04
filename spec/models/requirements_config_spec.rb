require 'rails_helper'

RSpec.describe RequirementsConfig, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:consents_required) }
    it { should validate_presence_of(:verification_steps) }
    it { should validate_presence_of(:signature) }
  end

  describe 'relationships' do
    it { should have_many(:form_submissions) }
  end

  describe 'methods' do
    let(:requirements_config) do
      RequirementsConfig.new(
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
          'mode' => 'electronic'
        }
      )
    end

    describe '#consents_required?' do
      it 'returns true if the consent is required' do
        expect(requirements_config.consents_required?('driver_license')).to be true
        expect(requirements_config.consents_required?('biometric')).to be true
      end

      it 'returns false if the consent is not required' do
        expect(requirements_config.consents_required?('drug_test')).to be false
      end
    end

    describe '#verification_step_enabled?' do
      it 'returns true if the step is enabled' do
        expect(requirements_config.verification_step_enabled?('personalInfo')).to be true
        expect(requirements_config.verification_step_enabled?('residenceHistory')).to be true
        expect(requirements_config.verification_step_enabled?('education')).to be true
      end

      it 'returns false if the step is not enabled' do
        expect(requirements_config.verification_step_enabled?('employmentHistory')).to be false
        expect(requirements_config.verification_step_enabled?('professionalLicense')).to be false
      end
    end

    describe '#residence_history_years' do
      it 'returns the number of years required for residence history' do
        expect(requirements_config.residence_history_years).to eq(3)
      end
    end

    describe '#signature_required?' do
      it 'returns true if signature is required' do
        expect(requirements_config.signature_required?).to be true
      end
    end

    describe '#signature_mode' do
      it 'returns the signature mode' do
        expect(requirements_config.signature_mode).to eq('electronic')
      end
    end
  end
end
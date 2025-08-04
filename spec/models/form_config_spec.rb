require 'rails_helper'

RSpec.describe FormConfig, type: :model do
  describe '.find_step' do
    it 'returns the step configuration for a valid step ID' do
      step = FormConfig.find_step('personal_info')
      expect(step).to be_a(Hash)
      expect(step[:id]).to eq('personal_info')
      expect(step[:fields]).to be_an(Array)
    end

    it 'returns nil for an invalid step ID' do
      step = FormConfig.find_step('invalid_step')
      expect(step).to be_nil
    end
  end

  describe '.step_ids' do
    it 'returns an array of step IDs' do
      step_ids = FormConfig.step_ids
      expect(step_ids).to be_an(Array)
      expect(step_ids).to include('personal_info', 'education', 'consents', 'signature')
    end
  end

  describe '.update_step_config' do
    it 'returns an updated step configuration' do
      updated_step = FormConfig.update_step_config('consents', { _config: { consents_required: { driver_license: true } } })
      expect(updated_step).to be_a(Hash)
      expect(updated_step[:id]).to eq('consents')
      expect(updated_step[:_config]).to eq({ consents_required: { driver_license: true } })
    end

    it 'returns false for an invalid step ID' do
      updated_step = FormConfig.update_step_config('invalid_step', { _config: {} })
      expect(updated_step).to be_falsey
    end
  end
end
require 'spec_helper'
require 'form_wizard/services/base_service'
require 'form_wizard/services/validation_service'

describe 'ValidationService' do
  it 'exists as a class' do
    expect(defined?(FormWizard::ValidationService)).to eq('constant')
  end
  
  describe 'Result class' do
    it 'can be instantiated' do
      result = FormWizard::BaseService::Result.new(success: true)
      expect(result).to be_success
      expect(result).to be_valid
      expect(result.next_step).to be_nil
    end
    
    it 'can store errors' do
      result = FormWizard::BaseService::Result.new(success: false, errors: ['Error 1', 'Error 2'])
      expect(result).not_to be_success
      expect(result).not_to be_valid
      expect(result.errors).to eq(['Error 1', 'Error 2'])
    end
    
    it 'can store next step' do
      result = FormWizard::BaseService::Result.new(next_step: 'next_step')
      expect(result.next_step).to eq('next_step')
    end
  end
end
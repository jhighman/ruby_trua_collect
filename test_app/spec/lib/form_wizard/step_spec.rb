require 'spec_helper'
require 'form_wizard/step'
require 'form_wizard/field'

describe 'FormWizard::Step' do
  it 'exists as a class' do
    expect(defined?(FormWizard::Step)).to eq('constant')
  end
  
  describe 'class methods' do
    it 'has a step_name class method' do
      expect(FormWizard::Step).to respond_to(:step_name)
    end
    
    it 'has a field class method' do
      expect(FormWizard::Step).to respond_to(:field)
    end
    
    it 'has a validate class method' do
      expect(FormWizard::Step).to respond_to(:validate)
    end
  end
end
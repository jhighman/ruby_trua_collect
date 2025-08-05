require 'spec_helper'
require 'form_wizard/flow'

describe 'FormWizard::Flow' do
  it 'exists as a class' do
    expect(defined?(FormWizard::Flow)).to eq('constant')
  end
  
  describe 'class methods' do
    it 'has a flow_name class method' do
      expect(FormWizard::Flow).to respond_to(:flow_name)
    end
    
    it 'has a step class method' do
      expect(FormWizard::Flow).to respond_to(:step)
    end
    
    it 'has a navigate_to class method' do
      expect(FormWizard::Flow).to respond_to(:navigate_to)
    end
    
    it 'has an on_complete class method' do
      expect(FormWizard::Flow).to respond_to(:on_complete)
    end
    
    it 'has an on_step_complete class method' do
      expect(FormWizard::Flow).to respond_to(:on_step_complete)
    end
  end
  
  describe 'instance methods' do
    let(:flow) { FormWizard::Flow.new }
    
    it 'has a steps method' do
      expect(flow).to respond_to(:steps)
    end
    
    it 'has an initial_step method' do
      expect(flow).to respond_to(:initial_step)
    end
    
    it 'has a next_step method' do
      expect(flow).to respond_to(:next_step)
    end
  end
end
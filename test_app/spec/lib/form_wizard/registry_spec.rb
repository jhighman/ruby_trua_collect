require 'spec_helper'
require 'form_wizard/registry'

describe 'FormWizard::Registry' do
  let(:registry) { FormWizard::Registry.new }
  
  # Create a test step class
  before do
    # Mock the FormWizard module to avoid the register_step call in Step.inherited
    module FormWizard
      def self.register_step(step_class)
        # Do nothing in test
      end
    end
    
    # Define a test step class
    class TestStep
      def self.name
        :test_step
      end
      
      def initialize
        # Test implementation
      end
    end
  end
  
  after do
    # Clean up the test class
    Object.send(:remove_const, :TestStep) if defined?(TestStep)
  end
  
  it 'exists as a class' do
    expect(defined?(FormWizard::Registry)).to eq('constant')
  end
  
  describe '#register' do
    it 'registers a step class' do
      registry.register(TestStep)
      expect(registry.instance_variable_get(:@registry)[:test_step]).to eq(TestStep)
    end
    
    it 'ignores registration if step name is nil' do
      step_class = Class.new do
        def self.name
          nil
        end
      end
      registry.register(step_class)
      expect(registry.instance_variable_get(:@registry)).to be_empty
    end
  end
  
  describe '#find' do
    before do
      registry.register(TestStep)
    end
    
    it 'finds a registered step by name' do
      step = registry.find(:test_step)
      expect(step).to be_a(TestStep)
    end
    
    it 'returns nil if step name is nil' do
      expect(registry.find(nil)).to be_nil
    end
    
    it 'returns nil if step is not registered' do
      expect(registry.find(:nonexistent_step)).to be_nil
    end
  end
  
  describe '#all' do
    before do
      registry.register(TestStep)
    end
    
    it 'returns all registered steps as instances' do
      steps = registry.all
      expect(steps.size).to eq(1)
      expect(steps.first).to be_a(TestStep)
    end
  end
  
  describe '#clear' do
    before do
      registry.register(TestStep)
    end
    
    it 'clears all registered steps' do
      registry.clear
      expect(registry.instance_variable_get(:@registry)).to be_empty
    end
  end
end
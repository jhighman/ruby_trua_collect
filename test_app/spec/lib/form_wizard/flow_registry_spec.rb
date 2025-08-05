require 'spec_helper'
require 'form_wizard/flow_registry'

describe 'FormWizard::FlowRegistry' do
  let(:registry) { FormWizard::FlowRegistry.new }
  
  # Create a test flow class
  before do
    # Mock the FormWizard module to avoid the register_flow call in Flow.inherited
    module FormWizard
      def self.register_flow(flow_class)
        # Do nothing in test
      end
    end
    
    # Define a test flow class
    class TestFlow
      def self.name
        :test_flow
      end
      
      def initialize
        # Test implementation
      end
    end
  end
  
  after do
    # Clean up the test class
    Object.send(:remove_const, :TestFlow) if defined?(TestFlow)
  end
  
  it 'exists as a class' do
    expect(defined?(FormWizard::FlowRegistry)).to eq('constant')
  end
  
  describe '#register' do
    it 'registers a flow class' do
      registry.register(TestFlow)
      expect(registry.instance_variable_get(:@registry)[:test_flow]).to eq(TestFlow)
    end
    
    it 'ignores registration if flow name is nil' do
      flow_class = Class.new do
        def self.name
          nil
        end
      end
      registry.register(flow_class)
      expect(registry.instance_variable_get(:@registry)).to be_empty
    end
  end
  
  describe '#find' do
    before do
      registry.register(TestFlow)
    end
    
    it 'finds a registered flow by name' do
      flow = registry.find(:test_flow)
      expect(flow).to be_a(TestFlow)
    end
    
    it 'returns nil if flow name is nil' do
      expect(registry.find(nil)).to be_nil
    end
    
    it 'returns nil if flow is not registered' do
      expect(registry.find(:nonexistent_flow)).to be_nil
    end
  end
  
  describe '#all' do
    before do
      registry.register(TestFlow)
    end
    
    it 'returns all registered flows as instances' do
      flows = registry.all
      expect(flows.size).to eq(1)
      expect(flows.first).to be_a(TestFlow)
    end
  end
  
  describe '#clear' do
    before do
      registry.register(TestFlow)
    end
    
    it 'clears all registered flows' do
      registry.clear
      expect(registry.instance_variable_get(:@registry)).to be_empty
    end
  end
end
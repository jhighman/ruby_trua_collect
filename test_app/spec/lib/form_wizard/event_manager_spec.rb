require 'spec_helper'
require 'form_wizard/event_manager'

describe 'FormWizard::EventManager' do
  let(:event_manager) { FormWizard::EventManager.new }
  
  it 'exists as a class' do
    expect(defined?(FormWizard::EventManager)).to eq('constant')
  end
  
  describe '#subscribe' do
    it 'adds a subscriber to an event' do
      event_manager.subscribe(:test_event) { |data| data }
      expect(event_manager.instance_variable_get(:@subscribers)[:test_event]).not_to be_empty
    end
    
    it 'allows multiple subscribers for the same event' do
      event_manager.subscribe(:test_event) { |data| data + 1 }
      event_manager.subscribe(:test_event) { |data| data + 2 }
      
      subscribers = event_manager.instance_variable_get(:@subscribers)[:test_event]
      expect(subscribers.size).to eq(2)
    end
  end
  
  describe '#publish' do
    it 'calls all subscribers for an event' do
      result1 = nil
      result2 = nil
      
      event_manager.subscribe(:test_event) { |data| result1 = data + 1 }
      event_manager.subscribe(:test_event) { |data| result2 = data + 2 }
      
      event_manager.publish(:test_event, 5)
      
      expect(result1).to eq(6)
      expect(result2).to eq(7)
    end
    
    it 'does nothing if there are no subscribers' do
      expect { event_manager.publish(:nonexistent_event, 5) }.not_to raise_error
    end
    
    it 'passes multiple arguments to subscribers' do
      result = nil
      
      event_manager.subscribe(:test_event) { |arg1, arg2| result = arg1 + arg2 }
      
      event_manager.publish(:test_event, 5, 10)
      
      expect(result).to eq(15)
    end
  end
  
  describe '#clear' do
    it 'removes all subscribers' do
      event_manager.subscribe(:test_event) { |data| data }
      event_manager.clear
      
      expect(event_manager.instance_variable_get(:@subscribers)).to be_empty
    end
  end
end
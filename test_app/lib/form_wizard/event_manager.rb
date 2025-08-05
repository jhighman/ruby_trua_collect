# frozen_string_literal: true

module FormWizard
  class EventManager
    def initialize
      @subscribers = {}
    end
    
    def subscribe(event_name, &block)
      @subscribers[event_name.to_sym] ||= []
      @subscribers[event_name.to_sym] << block
    end
    
    def publish(event_name, *args)
      return unless @subscribers[event_name.to_sym]
      
      @subscribers[event_name.to_sym].each do |subscriber|
        subscriber.call(*args)
      end
    end
    
    def clear
      @subscribers = {}
    end
  end
end
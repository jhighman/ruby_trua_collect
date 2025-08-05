# frozen_string_literal: true

module FormWizard
  # Manages events for the form wizard
  class EventManager
    class << self
      # Get all event subscribers
      # @return [Hash] The subscribers
      def subscribers
        @subscribers ||= Hash.new { |h, k| h[k] = [] }
      end
      
      # Subscribe to an event
      # @param event [Symbol] The event to subscribe to
      # @param block [Block] The handler for the event
      def subscribe(event, &block)
        subscribers[event] << block
        
        # Return an unsubscribe proc
        -> { unsubscribe(event, block) }
      end
      
      # Unsubscribe from an event
      # @param event [Symbol] The event to unsubscribe from
      # @param block [Block] The handler to unsubscribe
      def unsubscribe(event, block)
        subscribers[event].delete(block)
      end
      
      # Publish an event
      # @param event [Symbol] The event to publish
      # @param args [Array] Arguments to pass to the event handlers
      def publish(event, *args)
        subscribers[event].each { |subscriber| subscriber.call(*args) }
      end
      
      # Clear all subscribers
      # Mainly used for testing
      def clear
        @subscribers = Hash.new { |h, k| h[k] = [] }
      end
    end
  end
end
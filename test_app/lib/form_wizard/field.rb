# frozen_string_literal: true

module FormWizard
  class Field
    attr_reader :name, :type, :options, :label, :hint, :placeholder, 
                :required, :pattern, :pattern_message, :min, :max, 
                :depends_on, :depends_on_value, :rows, :prompt
    
    def initialize(name, options = {})
      @name = name
      @type = options[:type] || :text
      @options = options[:options]
      @label = options[:label] || name.to_s.humanize
      @hint = options[:hint]
      @placeholder = options[:placeholder]
      @required = options[:required] || false
      @pattern = options[:pattern]
      @pattern_message = options[:pattern_message]
      @min = options[:min]
      @max = options[:max]
      @depends_on = options[:depends_on]
      @depends_on_value = options[:depends_on_value]
      @rows = options[:rows]
      @prompt = options[:prompt]
    end
    
    def required?
      @required
    end
  end
end
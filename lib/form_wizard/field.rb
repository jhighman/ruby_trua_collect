# frozen_string_literal: true

module FormWizard
  # Represents a field in a form step
  class Field
    attr_reader :id, :options, :validations
    
    # Initialize a new field
    # @param id [Symbol, String] The unique identifier for the field
    # @param options [Hash] Options for the field
    def initialize(id, options = {})
      @id = id.to_sym
      @options = options
      @validations = []
    end
    
    # Get the field type
    # @return [Symbol] The field type
    def type
      @options[:type]&.to_sym || :string
    end
    
    # Get the field label
    # @return [String] The field label
    def label
      @options[:label] || @id.to_s.humanize
    end
    
    # Check if the field is required
    # @return [Boolean] Whether the field is required
    def required?
      !!@options[:required]
    end
    
    # Get the field placeholder
    # @return [String, nil] The field placeholder
    def placeholder
      @options[:placeholder]
    end
    
    # Get the field help text
    # @return [String, nil] The field help text
    def help_text
      @options[:help_text]
    end
    
    # Get the field options (for select, radio, etc.)
    # @return [Array, nil] The field options
    def choices
      @options[:options] || @options[:choices]
    end
    
    # Add a validation rule
    # @param type [Symbol] The validation type
    # @param options [Hash] Validation options
    # @param block [Block] Custom validation block
    def validates(type, options = {}, &block)
      if block_given?
        @validations << { type: :custom, block: block }
      else
        @validations << { type: type, **options }
      end
    end
    
    # Validate the field value
    # @param value [Object] The value to validate
    # @return [String, nil] The error message if invalid, nil if valid
    def validate(value)
      # Skip validation for non-required empty values
      return nil if !required? && (value.nil? || value.to_s.empty?)
      
      # Check required
      return "#{label} is required" if required? && (value.nil? || value.to_s.empty?)
      
      # Run validations
      @validations.each do |validation|
        case validation[:type]
        when :format
          return validation[:message] if validation[:with] && !validation[:with].match?(value.to_s)
        when :length
          if validation[:minimum] && value.to_s.length < validation[:minimum]
            return validation[:message] || "#{label} is too short (minimum is #{validation[:minimum]} characters)"
          end
          if validation[:maximum] && value.to_s.length > validation[:maximum]
            return validation[:message] || "#{label} is too long (maximum is #{validation[:maximum]} characters)"
          end
        when :inclusion
          if validation[:in] && !validation[:in].include?(value)
            return validation[:message] || "#{label} is not included in the list"
          end
        when :exclusion
          if validation[:in] && validation[:in].include?(value)
            return validation[:message] || "#{label} is reserved"
          end
        when :numericality
          unless value.to_s =~ /\A[+-]?\d+(\.\d+)?\z/
            return validation[:message] || "#{label} is not a number"
          end
        when :custom
          if validation[:block]
            result = validation[:block].call(value)
            return result if result.is_a?(String)
          end
        end
      end
      
      nil # No validation errors
    end
    
    # Convert the field to a hash
    # @return [Hash] The field as a hash
    def to_h
      {
        id: @id,
        type: type,
        label: label,
        required: required?,
        validations: @validations.map { |v| v[:type] },
        **@options
      }
    end
  end
end
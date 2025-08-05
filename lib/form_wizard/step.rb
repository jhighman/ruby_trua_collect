# frozen_string_literal: true

module FormWizard
  # Represents a step in the form wizard
  class Step
    attr_reader :id, :fields, :position, :options, :validations, :completion_criteria
    
    # Initialize a new step
    # @param id [Symbol, String] The unique identifier for the step
    # @param options [Hash] Options for the step
    def initialize(id, options = {})
      @id = id.to_sym
      @options = options
      @position = options[:position]
      @fields = []
      @validations = []
      @completion_criteria = nil
      @render_proc = nil
    end
    
    # Set the title for the step
    # @param title [String] The title
    def title(title)
      @options[:title] = title
    end
    
    # Set the description for the step
    # @param description [String] The description
    def description(description)
      @options[:description] = description
    end
    
    # Define a field for the step
    # @param id [Symbol, String] The unique identifier for the field
    # @param options [Hash] Options for the field
    # @param block [Block] Configuration block for the field
    # @return [Field] The created field
    def field(id, options = {}, &block)
      field = Field.new(id, options)
      field.instance_eval(&block) if block_given?
      @fields << field
      field
    end
    
    # Add a validation rule for the step
    # @param block [Block] The validation rule
    def validate(&block)
      @validations << block
    end
    
    # Set the completion criteria for the step
    # @param block [Block] The completion criteria
    def completion_criteria(&block)
      @completion_criteria = block
    end
    
    # Set a custom render procedure for the step
    # @param block [Block] The render procedure
    def render(&block)
      @render_proc = block
    end
    
    # Get the render procedure
    # @return [Proc, nil] The render procedure
    def render_proc
      @render_proc
    end
    
    # Check if the step is valid
    # @param values [Hash] The values to validate
    # @param form_submission [FormSubmission] The form submission
    # @return [Hash] Validation result with :is_valid and :errors keys
    def valid?(values, form_submission = nil)
      errors = {}
      
      # Validate required fields
      @fields.each do |field|
        if field.required? && (values[field.id.to_s].nil? || values[field.id.to_s].to_s.empty?)
          errors[field.id.to_s] = "#{field.label} is required"
        end
      end
      
      # Run custom validations
      @validations.each do |validation|
        result = validation.call(values, form_submission)
        errors.merge!(result) if result.is_a?(Hash)
      end
      
      { is_valid: errors.empty?, errors: errors }
    end
    
    # Check if the step is complete
    # @param values [Hash] The values to check
    # @param form_submission [FormSubmission] The form submission
    # @return [Boolean] Whether the step is complete
    def complete?(values, form_submission = nil)
      return @completion_criteria.call(values, form_submission) if @completion_criteria
      
      # Default completion criteria: all required fields have values
      @fields.all? do |field|
        !field.required? || (values[field.id.to_s] && !values[field.id.to_s].to_s.empty?)
      end
    end
    
    # Convert the step to a hash
    # @return [Hash] The step as a hash
    def to_h
      {
        id: @id,
        fields: @fields.map(&:to_h),
        **@options
      }
    end
  end
end
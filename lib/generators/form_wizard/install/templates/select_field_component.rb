# frozen_string_literal: true

module FormWizard
  module Fields
    class SelectFieldComponent < BaseFieldComponent
      def call
        render(BaseFieldComponent.new(field: field, form_submission: form_submission, value: value, error: error)) do
          tag.select(name: field_name, **input_attributes) do
            options_html
          end
        end
      end
      
      private
      
      def options_html
        safe_join([prompt_option, *options_for_select])
      end
      
      def prompt_option
        return nil unless field.prompt
        
        tag.option(field.prompt, value: '', selected: value.blank?)
      end
      
      def options_for_select
        options = field.options || []
        
        options.map do |option|
          option_value = option.is_a?(Array) ? option[1] : option
          option_text = option.is_a?(Array) ? option[0] : option
          
          tag.option(option_text, value: option_value, selected: option_value.to_s == value.to_s)
        end
      end
    end
  end
end
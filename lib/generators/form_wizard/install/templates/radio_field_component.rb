# frozen_string_literal: true

module FormWizard
  module Fields
    class RadioFieldComponent < BaseFieldComponent
      def call
        render(BaseFieldComponent.new(field: field, form_submission: form_submission, value: value, error: error)) do
          content_tag(:div, class: 'radio-group') do
            safe_join(radio_buttons)
          end
        end
      end
      
      private
      
      def radio_buttons
        options = field.options || []
        
        options.map.with_index do |option, index|
          option_value = option.is_a?(Array) ? option[1] : option
          option_text = option.is_a?(Array) ? option[0] : option
          option_id = "#{field_id}_#{index}"
          
          content_tag(:div, class: 'form-check') do
            safe_join([
              tag.input(
                type: 'radio',
                name: field_name,
                id: option_id,
                value: option_value,
                checked: option_value.to_s == value.to_s,
                class: 'form-check-input',
                **data_attributes
              ),
              tag.label(option_text, for: option_id, class: 'form-check-label')
            ])
          end
        end
      end
    end
  end
end
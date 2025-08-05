# frozen_string_literal: true

module FormWizard
  module Fields
    class CheckboxFieldComponent < BaseFieldComponent
      def call
        render(BaseFieldComponent.new(field: field, form_submission: form_submission, value: value, error: error)) do
          content_tag(:div, class: 'form-check') do
            safe_join([
              tag.input(
                type: 'checkbox',
                name: field_name,
                id: field_id,
                value: '1',
                checked: value.present? && value != false,
                class: 'form-check-input',
                **data_attributes
              ),
              tag.label(label, for: field_id, class: 'form-check-label')
            ])
          end
        end
      end
      
      def css_classes
        classes = ['form-group', 'checkbox-field']
        classes << 'field-required' if required?
        classes << 'field-with-error' if error.present?
        classes.join(' ')
      end
    end
  end
end
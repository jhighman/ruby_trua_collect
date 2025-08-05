# frozen_string_literal: true

module FormWizard
  module Fields
    class TextFieldComponent < BaseFieldComponent
      def call
        render(BaseFieldComponent.new(field: field, form_submission: form_submission, value: value, error: error)) do
          tag.input(
            type: 'text',
            name: field_name,
            value: value,
            **input_attributes
          )
        end
      end
    end
  end
end
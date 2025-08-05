# frozen_string_literal: true

module FormWizard
  module Fields
    class TextareaFieldComponent < BaseFieldComponent
      def call
        render(BaseFieldComponent.new(field: field, form_submission: form_submission, value: value, error: error)) do
          tag.textarea(
            value.to_s,
            name: field_name,
            rows: rows,
            **input_attributes
          )
        end
      end
      
      private
      
      def rows
        field.rows || 5
      end
    end
  end
end
# frozen_string_literal: true

module FormWizard
  module Fields
    class DateFieldComponent < BaseFieldComponent
      def call
        render(BaseFieldComponent.new(field: field, form_submission: form_submission, value: value, error: error)) do
          tag.input(
            type: 'date',
            name: field_name,
            value: formatted_value,
            **input_attributes
          )
        end
      end
      
      private
      
      def formatted_value
        return nil if value.blank?
        
        if value.is_a?(Date) || value.is_a?(Time) || value.is_a?(DateTime)
          value.strftime('%Y-%m-%d')
        else
          value.to_s
        end
      end
    end
  end
end
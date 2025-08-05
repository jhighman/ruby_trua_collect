# frozen_string_literal: true

module FormWizard
  module Fields
    class BaseFieldComponent < ViewComponent::Base
      attr_reader :field, :form_submission, :value, :error
      
      def initialize(field:, form_submission:, value: nil, error: nil)
        @field = field
        @form_submission = form_submission
        @value = value
        @error = error
      end
      
      def render?
        field.present?
      end
      
      def field_name
        "form_submission[data][#{field.name}]"
      end
      
      def field_id
        "form_submission_data_#{field.name}"
      end
      
      def label
        field.label || field.name.to_s.humanize
      end
      
      def required?
        field.required?
      end
      
      def hint
        field.hint
      end
      
      def placeholder
        field.placeholder || label
      end
      
      def css_classes
        classes = ['form-group']
        classes << 'field-required' if required?
        classes << 'field-with-error' if error.present?
        classes.join(' ')
      end
      
      def input_css_classes
        classes = ['form-control']
        classes << 'is-invalid' if error.present?
        classes.join(' ')
      end
      
      def data_attributes
        attrs = {}
        
        if field.depends_on.present?
          attrs['data-depends-on'] = field.depends_on
          attrs['data-depends-on-value'] = field.depends_on_value
        end
        
        if field.pattern.present?
          attrs['data-pattern-message'] = field.pattern_message || 'Invalid format'
        end
        
        attrs
      end
      
      def input_attributes
        attrs = {
          id: field_id,
          class: input_css_classes,
          placeholder: placeholder
        }
        
        attrs[:required] = true if required?
        attrs[:pattern] = field.pattern if field.pattern.present?
        
        if field.min.present?
          attrs[:min] = field.min
        end
        
        if field.max.present?
          attrs[:max] = field.max
        end
        
        attrs.merge(data_attributes)
      end
    end
  end
end
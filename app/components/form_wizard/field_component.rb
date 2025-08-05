# frozen_string_literal: true

module FormWizard
  # Component for rendering a form field
  class FieldComponent < ViewComponent::Base
    # Initialize a new component
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param field [Field] The field
    # @param value [Object] The field value
    # @param error [String] The field error
    def initialize(form:, field:, value: nil, error: nil)
      @form = form
      @field = field.is_a?(::FormWizard::Field) ? field : ::FormWizard::Field.new(field[:id], field)
      @value = value
      @error = error
    end
    
    # Get the form builder
    # @return [ActionView::Helpers::FormBuilder] The form builder
    attr_reader :form
    
    # Get the field
    # @return [Field] The field
    attr_reader :field
    
    # Get the field value
    # @return [Object] The field value
    attr_reader :value
    
    # Get the field error
    # @return [String] The field error
    attr_reader :error
    
    # Render the component
    # @return [String] The rendered component
    def call
      component_for_type.new(
        form: form,
        field: field,
        value: value,
        error: error
      ).call
    end
    
    # Get the component class for the field type
    # @return [Class] The component class
    def component_for_type
      case field.type
      when :string, :text
        TextFieldComponent
      when :email
        EmailFieldComponent
      when :password
        PasswordFieldComponent
      when :number
        NumberFieldComponent
      when :select
        SelectFieldComponent
      when :radio
        RadioFieldComponent
      when :checkbox
        CheckboxFieldComponent
      when :date
        DateFieldComponent
      when :datetime
        DatetimeFieldComponent
      when :time
        TimeFieldComponent
      when :file
        FileFieldComponent
      when :hidden
        HiddenFieldComponent
      else
        TextFieldComponent
      end
    end
    
    # Base class for field components
    class BaseFieldComponent < ViewComponent::Base
      # Initialize a new component
      # @param form [ActionView::Helpers::FormBuilder] The form builder
      # @param field [Field] The field
      # @param value [Object] The field value
      # @param error [String] The field error
      def initialize(form:, field:, value: nil, error: nil)
        @form = form
        @field = field
        @value = value
        @error = error
      end
      
      # Get the form builder
      # @return [ActionView::Helpers::FormBuilder] The form builder
      attr_reader :form
      
      # Get the field
      # @return [Field] The field
      attr_reader :field
      
      # Get the field value
      # @return [Object] The field value
      attr_reader :value
      
      # Get the field error
      # @return [String] The field error
      attr_reader :error
      
      # Get the field ID
      # @return [String] The field ID
      def field_id
        field.id.to_s
      end
      
      # Get the field name
      # @return [String] The field name
      def field_name
        "form_submission[#{field_id}]"
      end
      
      # Get the field label
      # @return [String] The field label
      def field_label
        field.label
      end
      
      # Get the field placeholder
      # @return [String] The field placeholder
      def field_placeholder
        field.placeholder
      end
      
      # Get the field help text
      # @return [String] The field help text
      def field_help_text
        field.help_text
      end
      
      # Check if the field is required
      # @return [Boolean] Whether the field is required
      def field_required?
        field.required?
      end
      
      # Get the field CSS classes
      # @return [String] The field CSS classes
      def field_classes
        classes = ['form-control']
        classes << 'is-invalid' if error.present?
        classes.join(' ')
      end
      
      # Get the field data attributes
      # @return [Hash] The field data attributes
      def field_data
        {
          form_wizard_target: 'field'
        }
      end
      
      # Render the field wrapper
      # @param content [String] The field content
      # @return [String] The rendered field wrapper
      def render_wrapper(&block)
        content_tag :div, class: 'mb-3' do
          concat(render_label)
          concat(capture(&block))
          concat(render_error)
          concat(render_help_text)
        end
      end
      
      # Render the field label
      # @return [String] The rendered field label
      def render_label
        form.label field_id, field_label, class: 'form-label'
      end
      
      # Render the field error
      # @return [String] The rendered field error
      def render_error
        return unless error.present?
        
        content_tag :div, error, class: 'invalid-feedback'
      end
      
      # Render the field help text
      # @return [String] The rendered field help text
      def render_help_text
        return unless field_help_text.present?
        
        content_tag :div, field_help_text, class: 'form-text'
      end
    end
    
    # Component for rendering a text field
    class TextFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.text_field(
            field_id,
            value: value,
            class: field_classes,
            placeholder: field_placeholder,
            required: field_required?,
            data: field_data
          )
        end
      end
    end
    
    # Component for rendering an email field
    class EmailFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.email_field(
            field_id,
            value: value,
            class: field_classes,
            placeholder: field_placeholder,
            required: field_required?,
            data: field_data
          )
        end
      end
    end
    
    # Component for rendering a password field
    class PasswordFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.password_field(
            field_id,
            value: value,
            class: field_classes,
            placeholder: field_placeholder,
            required: field_required?,
            data: field_data
          )
        end
      end
    end
    
    # Component for rendering a number field
    class NumberFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.number_field(
            field_id,
            value: value,
            class: field_classes,
            placeholder: field_placeholder,
            required: field_required?,
            data: field_data,
            min: field.options[:min],
            max: field.options[:max],
            step: field.options[:step]
          )
        end
      end
    end
    
    # Component for rendering a select field
    class SelectFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.select(
            field_id,
            options_for_select(field.choices, value),
            { include_blank: !field_required? },
            {
              class: field_classes,
              required: field_required?,
              data: field_data
            }
          )
        end
      end
    end
    
    # Component for rendering a radio field
    class RadioFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        content_tag :fieldset, class: 'mb-3' do
          concat(content_tag(:legend, field_label, class: 'form-label'))
          
          field.choices.each do |choice|
            concat(
              content_tag(:div, class: 'form-check') do
                concat(
                  form.radio_button(
                    field_id,
                    choice,
                    checked: value == choice,
                    class: 'form-check-input',
                    required: field_required?,
                    data: field_data
                  )
                )
                concat(
                  form.label(
                    "#{field_id}_#{choice}",
                    choice.to_s.humanize,
                    class: 'form-check-label'
                  )
                )
              end
            )
          end
          
          concat(render_error)
          concat(render_help_text)
        end
      end
    end
    
    # Component for rendering a checkbox field
    class CheckboxFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        content_tag :div, class: 'mb-3 form-check' do
          concat(
            form.check_box(
              field_id,
              checked: value,
              class: 'form-check-input',
              required: field_required?,
              data: field_data
            )
          )
          concat(
            form.label(
              field_id,
              field_label,
              class: 'form-check-label'
            )
          )
          concat(render_error)
          concat(render_help_text)
        end
      end
    end
    
    # Component for rendering a date field
    class DateFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.date_field(
            field_id,
            value: value,
            class: field_classes,
            required: field_required?,
            data: field_data
          )
        end
      end
    end
    
    # Component for rendering a datetime field
    class DatetimeFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.datetime_field(
            field_id,
            value: value,
            class: field_classes,
            required: field_required?,
            data: field_data
          )
        end
      end
    end
    
    # Component for rendering a time field
    class TimeFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.time_field(
            field_id,
            value: value,
            class: field_classes,
            required: field_required?,
            data: field_data
          )
        end
      end
    end
    
    # Component for rendering a file field
    class FileFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        render_wrapper do
          form.file_field(
            field_id,
            class: field_classes,
            required: field_required?,
            data: field_data,
            accept: field.options[:accept]
          )
        end
      end
    end
    
    # Component for rendering a hidden field
    class HiddenFieldComponent < BaseFieldComponent
      # Render the component
      # @return [String] The rendered component
      def call
        form.hidden_field(
          field_id,
          value: value,
          data: field_data
        )
      end
    end
  end
end
# frozen_string_literal: true

module FormWizard
  # Component for rendering a form
  class FormComponent < BaseComponent
    # Render the component
    # @return [String] The rendered component
    def call
      render(FormWizard::FormComponent::Template.new(
        form_submission: form_submission,
        step_id: step_id,
        options: options
      ))
    end
    
    # Template for the form component
    class Template < BaseComponent
      # Render the component
      # @return [String] The rendered component
      def call
        content_tag :div, class: 'form-wizard-form' do
          form_with(
            model: form_submission,
            url: form_submission_path(step_id: step_id),
            method: :patch,
            class: 'needs-validation',
            data: {
              controller: 'form-wizard',
              form_wizard_step_id_value: step_id,
              form_wizard_form_id_value: form_submission.id
            }
          ) do |form|
            concat(render_errors)
            concat(render_fields(form))
            concat(render_navigation(form))
          end
        end
      end
      
      private
      
      # Render the error messages
      # @return [String] The rendered error messages
      def render_errors
        return unless step_errors.any?
        
        content_tag :div, class: 'alert alert-danger' do
          content_tag :ul, class: 'mb-0' do
            step_errors.map do |field, error|
              content_tag :li, "#{field.to_s.humanize}: #{error}"
            end.join.html_safe
          end
        end
      end
      
      # Render the form fields
      # @param form [ActionView::Helpers::FormBuilder] The form builder
      # @return [String] The rendered form fields
      def render_fields(form)
        content_tag :div, class: 'form-fields' do
          current_step.fields.map do |field|
            render(FormWizard::FieldComponent.new(
              form: form,
              field: field,
              value: step_values[field.id.to_s],
              error: step_errors[field.id.to_s]
            ))
          end.join.html_safe
        end
      end
      
      # Render the navigation buttons
      # @param form [ActionView::Helpers::FormBuilder] The form builder
      # @return [String] The rendered navigation buttons
      def render_navigation(form)
        content_tag :div, class: 'form-navigation d-flex justify-content-between mt-4' do
          concat(render_previous_button(form))
          concat(render_next_button(form))
        end
      end
      
      # Render the previous button
      # @param form [ActionView::Helpers::FormBuilder] The form builder
      # @return [String] The rendered previous button
      def render_previous_button(form)
        return unless navigation_state[:can_move_previous]
        
        form.submit 'Previous', name: 'commit', value: 'Previous', class: 'btn btn-outline-secondary'
      end
      
      # Render the next button
      # @param form [ActionView::Helpers::FormBuilder] The form builder
      # @return [String] The rendered next button
      def render_next_button(form)
        if navigation_state[:can_move_next]
          form.submit 'Next', name: 'commit', value: 'Next', class: 'btn btn-primary'
        elsif service.navigation.last_step?(step_id)
          form.submit 'Submit', name: 'commit', value: 'Submit', class: 'btn btn-success'
        else
          form.submit 'Save', name: 'commit', value: 'Save', class: 'btn btn-primary'
        end
      end
    end
  end
end
# frozen_string_literal: true

module FormWizard
  class WizardComponent < ViewComponent::Base
    attr_reader :form_submission, :step, :flow, :errors
    
    def initialize(form_submission:, step:, flow:, errors: nil)
      @form_submission = form_submission
      @step = step.to_s
      @flow = flow
      @errors = errors || []
      
      @step_instance = FormWizard.find_step(step)
      @previous_step = flow.previous_step(step)
      @next_step = flow.next_step(step)
    end
    
    def render?
      @step_instance.present?
    end
    
    def step_title
      I18n.t("form_wizard.steps.#{step}.title", default: @step_instance.title || step.humanize)
    end
    
    def step_description
      I18n.t("form_wizard.steps.#{step}.description", default: @step_instance.description || '')
    end
    
    def progress_percentage
      form_submission.progress_percentage(flow)
    end
    
    def steps
      flow.steps
    end
    
    def current_step_index
      steps.index(step.to_sym) || 0
    end
    
    def step_completed?(step_name)
      form_submission.step_completed?(step_name.to_s)
    end
    
    def field_value(field_name)
      form_submission.get_field_value(field_name)
    end
    
    def field_error(field_name)
      errors.find { |e| e.to_s.include?(field_name.to_s) }
    end
    
    def render_field(field)
      component = field_component_for(field)
      render(component) if component
    end
    
    private
    
    def field_component_for(field)
      component_class = "FormWizard::Fields::#{field.type.to_s.camelize}FieldComponent"
      component_class.constantize.new(
        field: field,
        form_submission: form_submission,
        value: field_value(field.name),
        error: field_error(field.name)
      )
    rescue NameError
      # Fallback to text field if specific component not found
      FormWizard::Fields::TextFieldComponent.new(
        field: field,
        form_submission: form_submission,
        value: field_value(field.name),
        error: field_error(field.name)
      )
    end
  end
end
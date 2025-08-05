# frozen_string_literal: true

module FormWizard
  class CompleteComponent < ViewComponent::Base
    attr_reader :form_submission, :flow
    
    def initialize(form_submission:, flow:)
      @form_submission = form_submission
      @flow = flow
    end
    
    def render?
      form_submission.completed?
    end
    
    def title
      I18n.t('form_wizard.complete.title', default: 'Form Completed')
    end
    
    def message
      I18n.t('form_wizard.complete.message', default: 'Thank you for completing the form.')
    end
    
    def submission_data
      data = {}
      
      flow.steps.each do |step_name|
        step = FormWizard.find_step(step_name)
        next unless step
        
        step.fields.each do |field|
          value = form_submission.get_field_value(field.name)
          data[field.name] = {
            label: field.label,
            value: format_value(value, field)
          }
        end
      end
      
      data
    end
    
    private
    
    def format_value(value, field)
      return 'Yes' if value == true && field.type == :boolean
      return 'No' if value == false && field.type == :boolean
      return value.strftime('%B %d, %Y') if value.is_a?(Date)
      return value.strftime('%B %d, %Y %H:%M') if value.is_a?(Time) || value.is_a?(DateTime)
      
      value.to_s
    end
  end
end
# frozen_string_literal: true

module FormWizard
  # Component for rendering the entire form wizard
  class WizardComponent < BaseComponent
    # Render the component
    # @return [String] The rendered component
    def call
      content_tag :div, class: 'form-wizard' do
        content_tag :div, class: 'container' do
          content_tag :div, class: 'row' do
            concat(render_sidebar)
            concat(render_content)
          end
        end
      end
    end
    
    private
    
    # Render the sidebar
    # @return [String] The rendered sidebar
    def render_sidebar
      content_tag :div, class: 'col-md-3' do
        render(FormWizard::ProgressComponent.new(
          form_submission: form_submission,
          step_id: step_id
        ))
      end
    end
    
    # Render the content
    # @return [String] The rendered content
    def render_content
      content_tag :div, class: 'col-md-9' do
        content_tag :div, class: 'card' do
          concat(render_header)
          concat(render_body)
        end
      end
    end
    
    # Render the header
    # @return [String] The rendered header
    def render_header
      return unless current_step
      
      content_tag :div, class: 'card-header' do
        content_tag :h2, current_step.options[:title] || current_step.id.to_s.humanize, class: 'card-title h5 mb-0'
      end
    end
    
    # Render the body
    # @return [String] The rendered body
    def render_body
      content_tag :div, class: 'card-body' do
        if current_step
          if current_step.options[:description].present?
            concat(content_tag(:p, current_step.options[:description], class: 'card-text mb-4'))
          end
          
          concat(render_form)
        else
          content_tag :div, class: 'alert alert-warning' do
            'No step found. Please configure the form wizard.'
          end
        end
      end
    end
    
    # Render the form
    # @return [String] The rendered form
    def render_form
      render(FormWizard::FormComponent.new(
        form_submission: form_submission,
        step_id: step_id
      ))
    end
  end
end
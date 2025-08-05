# frozen_string_literal: true

module FormWizard
  # Component for rendering form progress
  class ProgressComponent < BaseComponent
    # Render the component
    # @return [String] The rendered component
    def call
      content_tag :div, class: 'form-wizard-progress card mb-4' do
        content_tag :div, class: 'card-body' do
          concat(render_progress_bar)
          concat(render_step_list)
        end
      end
    end
    
    private
    
    # Render the progress bar
    # @return [String] The rendered progress bar
    def render_progress_bar
      content_tag :div, class: 'progress mb-3' do
        content_tag :div,
          "#{progress_percentage}%",
          class: 'progress-bar',
          role: 'progressbar',
          style: "width: #{progress_percentage}%",
          aria: {
            valuenow: progress_percentage,
            valuemin: 0,
            valuemax: 100
          }
      end
    end
    
    # Render the step list
    # @return [String] The rendered step list
    def render_step_list
      content_tag :ul, class: 'list-group list-group-flush' do
        available_steps.map do |step_id|
          render_step_item(step_id)
        end.join.html_safe
      end
    end
    
    # Render a step item
    # @param step_id [Symbol] The step ID
    # @return [String] The rendered step item
    def render_step_item(step_id)
      step = ::FormWizard.find_step(step_id)
      return unless step
      
      item_class = 'list-group-item d-flex justify-content-between align-items-center'
      item_class << ' active' if step_id == self.step_id
      item_class << ' list-group-item-success' if completed_steps.include?(step_id)
      
      content_tag :li, class: item_class do
        concat(render_step_title(step))
        concat(render_step_status(step_id))
      end
    end
    
    # Render a step title
    # @param step [Step] The step
    # @return [String] The rendered step title
    def render_step_title(step)
      title = step.options[:title] || step.id.to_s.humanize
      
      if service.navigation.step_enabled?(step.id) && step.id != self.step_id
        link_to title, form_submission_path(step_id: step.id), class: 'step-title'
      else
        content_tag :span, title, class: 'step-title'
      end
    end
    
    # Render a step status
    # @param step_id [Symbol] The step ID
    # @return [String] The rendered step status
    def render_step_status(step_id)
      if completed_steps.include?(step_id)
        content_tag :span, class: 'badge bg-success rounded-pill' do
          content_tag :i, nil, class: 'bi bi-check-lg'
        end
      elsif step_id == self.step_id
        content_tag :span, 'Current', class: 'badge bg-primary rounded-pill'
      else
        content_tag :span, 'Pending', class: 'badge bg-secondary rounded-pill'
      end
    end
    
    # Get the available steps
    # @return [Array<Symbol>] The available steps
    def available_steps
      service.navigation.available_steps
    end
    
    # Get the completed steps
    # @return [Array<Symbol>] The completed steps
    def completed_steps
      service.navigation.completed_steps
    end
  end
end
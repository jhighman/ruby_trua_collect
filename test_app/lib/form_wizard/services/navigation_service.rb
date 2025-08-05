# frozen_string_literal: true

module FormWizard
  class NavigationService < BaseService
    def next_step(current_step:, flow:)
      flow.next_step(current_step, form_submission)
    end
    
    def previous_step(current_step:, flow:)
      flow.previous_step(current_step)
    end
    
    def can_navigate_to?(step:, flow:)
      return true if form_submission.step_completed?(step.to_s)
      
      current_step = form_submission.current_step
      return false unless current_step
      
      # Can only navigate to the next step or a completed step
      next_step = flow.next_step(current_step, form_submission)
      step.to_s == next_step.to_s || form_submission.step_completed?(step.to_s)
    end
  end
end
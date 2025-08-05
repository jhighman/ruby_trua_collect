# frozen_string_literal: true

module FormWizard
  # Service for form wizard navigation
  class NavigationService < BaseService
    # Check if can move to next step
    # @return [Boolean] Whether can move to next step
    def can_move_next?
      return false unless current_step_id
      return false unless current_step_valid? && current_step_complete?
      
      !flow.last_step?(current_step_id)
    end
    
    # Check if can move to previous step
    # @return [Boolean] Whether can move to previous step
    def can_move_previous?
      return false unless current_step_id
      
      !flow.first_step?(current_step_id)
    end
    
    # Get the next step
    # @return [Symbol, nil] The next step, or nil if there is no next step
    def next_step
      return nil unless current_step_id
      
      flow.next_step(current_step_id, @form_submission)
    end
    
    # Get the previous step
    # @return [Symbol, nil] The previous step, or nil if there is no previous step
    def previous_step
      return nil unless current_step_id
      
      flow.previous_step(current_step_id, @form_submission)
    end
    
    # Move to the next step
    # @return [Boolean] Whether the move was successful
    def move_next
      return false unless can_move_next?
      
      next_step_id = next_step
      return false unless next_step_id
      
      move_to_step(next_step_id)
    end
    
    # Move to the previous step
    # @return [Boolean] Whether the move was successful
    def move_previous
      return false unless can_move_previous?
      
      prev_step_id = previous_step
      return false unless prev_step_id
      
      move_to_step(prev_step_id)
    end
    
    # Move to a specific step
    # @param step_id [Symbol, String] The step ID
    # @return [Boolean] Whether the move was successful
    def move_to_step(step_id)
      step_id = step_id.to_sym
      
      # Check if step is enabled
      return false unless step_enabled?(step_id)
      
      # Update the current step
      result = @form_submission.update(current_step_id: step_id)
      
      # Publish event
      publish(:step_changed, @form_submission, step_id) if result
      
      result
    end
    
    # Get the navigation state
    # @return [Hash] The navigation state
    def navigation_state
      {
        current_step: current_step_id,
        can_move_next: can_move_next?,
        can_move_previous: can_move_previous?,
        next_step: next_step,
        previous_step: previous_step,
        available_steps: available_steps,
        completed_steps: completed_steps,
        progress_percentage: progress_percentage
      }
    end
    
    # Get the progress percentage
    # @return [Integer] The progress percentage (0-100)
    def progress_percentage
      return 0 if available_steps.empty?
      
      completed_count = completed_steps.count
      total_count = available_steps.count
      
      # Add partial credit for current step if it's not completed
      if current_step_id && !completed_steps.include?(current_step_id)
        # Get the step state
        step_state = @form_submission.step_state(current_step_id)
        
        # Add partial credit based on validity
        completed_count += 0.5 if step_state && step_state[:is_valid]
      end
      
      ((completed_count.to_f / total_count) * 100).round
    end
    
    private
    
    # Check if the current step is valid
    # @return [Boolean] Whether the current step is valid
    def current_step_valid?
      @form_submission.step_valid?(current_step_id)
    end
    
    # Check if the current step is complete
    # @return [Boolean] Whether the current step is complete
    def current_step_complete?
      @form_submission.step_complete?(current_step_id)
    end
  end
end
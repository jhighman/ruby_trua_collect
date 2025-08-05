# frozen_string_literal: true

module FormWizard
  module Controller
    module FormWizardConcern
      extend ActiveSupport::Concern
      
      included do
        helper_method :current_step, :current_flow
      end
      
      # Helper methods
      
      def form_wizard_params
        params.require(:form_submission).permit!
      end
      
      def redirect_to_current_step
        redirect_to form_submission_path(step: current_step)
      end
      
      def redirect_to_next_step(next_step)
        if next_step
          redirect_to form_submission_path(step: next_step)
        else
          redirect_to complete_form_submission_path
        end
      end
      
      def render_step(step, errors = nil)
        @step = step
        @errors = errors
        @previous_step = current_flow.previous_step(step)
        @next_step = current_flow.next_step(step)
        
        render "form_wizard/steps/#{step}"
      end
      
      def render_with_errors(errors)
        render_step(current_step, errors)
      end
      
      def validate_current_step
        service = FormWizard::ValidationService.new(@form_submission)
        service.validate_step(
          step: current_step,
          params: form_wizard_params,
          flow: current_flow
        )
      end
      
      def process_current_step
        service = FormWizard::FormSubmissionService.new(@form_submission)
        service.process_step(
          step: current_step,
          params: form_wizard_params,
          flow: current_flow
        )
      end
    end
  end
end
# frozen_string_literal: true

module FormWizard
  class BaseService
    attr_reader :form_submission
    
    def initialize(form_submission)
      @form_submission = form_submission
    end
    
    class Result
      attr_reader :success, :errors, :next_step
      
      def initialize(success: true, errors: [], next_step: nil)
        @success = success
        @errors = errors
        @next_step = next_step
      end
      
      def success?
        @success
      end
      
      def valid?
        @errors.empty?
      end
    end
  end
end
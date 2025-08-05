# frozen_string_literal: true

class ReviewStep < FormWizard::Step
  step_name :review
  title 'Review Your Information'
  description 'Please review your information before submitting.'
  
  field :terms_accepted, type: :checkbox, required: true, label: 'I confirm that the information provided is correct'
  
  validate :validate_terms_accepted
  
  private
  
  def validate_terms_accepted(form_submission, params)
    unless params['terms_accepted'] == '1'
      add_error(:terms_accepted, 'You must confirm that the information is correct')
    end
  end
end
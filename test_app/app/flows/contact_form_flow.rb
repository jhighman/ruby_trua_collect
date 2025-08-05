# frozen_string_literal: true

class ContactFormFlow < FormWizard::Flow
  flow_name :contact_form
  
  step :personal_info
  step :contact_details
  step :review
  
  # Skip contact details if no email is provided
  navigate_to :review, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('first_name').blank? || form_submission.get_field_value('last_name').blank?
  }
  
  # Event handlers
  on_complete do |form_submission|
    # In a real application, this would send an email or save to a database
    Rails.logger.info "Form completed: #{form_submission.data.inspect}"
  end
  
  on_step_complete :personal_info do |form_submission|
    Rails.logger.info "Personal info step completed: #{form_submission.get_step_values(:personal_info).inspect}"
  end
  
  on_step_complete :contact_details do |form_submission|
    Rails.logger.info "Contact details step completed: #{form_submission.get_step_values(:contact_details).inspect}"
  end
  
  on_step_complete :review do |form_submission|
    Rails.logger.info "Review step completed: #{form_submission.get_step_values(:review).inspect}"
  end
end
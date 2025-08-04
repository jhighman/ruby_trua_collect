require 'rails_helper'

RSpec.describe FormSubmissionsController, type: :controller do
  describe "PATCH #update" do
    let(:requirements_config) { RequirementsConfig.create(
      verification_steps: {
        'personalInfo' => { 'enabled' => true },
        'education' => { 'enabled' => true },
        'residenceHistory' => { 'enabled' => true },
        'employmentHistory' => { 'enabled' => true },
        'professionalLicense' => { 'enabled' => true }
      },
      consents_required: {
        'driver_license' => true,
        'drug_test' => true,
        'biometric' => true
      },
      signature: { 'required' => true, 'mode' => 'draw' }
    )}
    
    let(:form_submission) { FormSubmission.create(requirements_config: requirements_config) }
    
    context "when submitting the personal_info step" do
      it "redirects to the next step" do
        patch :update, params: {
          id: form_submission.id,
          step_id: 'personal_info',
          commit: 'Next',
          form_submission: {
            name: 'Test User',
            email: 'test@example.com'
          }
        }
        
        expect(response).to redirect_to(form_submission_path(step_id: 'education'))
      end
    end
    
    context "when submitting the education step" do
      before do
        # Set up the form submission with completed personal_info step
        form_submission.update_step_state('personal_info', {
          values: { 'name' => 'Test User', 'email' => 'test@example.com' },
          is_valid: true,
          is_complete: true
        })
      end
      
      it "redirects to the next step" do
        patch :update, params: {
          id: form_submission.id,
          step_id: 'education',
          commit: 'Next',
          form_submission: {
            highest_level: 'high_school'
          }
        }
        
        expect(response).to redirect_to(form_submission_path(step_id: 'residence_history'))
      end
    end
    
    context "when navigating backwards" do
      before do
        # Set up the form submission with completed steps
        form_submission.update_step_state('personal_info', {
          values: { 'name' => 'Test User', 'email' => 'test@example.com' },
          is_valid: true,
          is_complete: true
        })
        
        form_submission.update_step_state('education', {
          values: { 'highest_level' => 'high_school' },
          is_valid: true,
          is_complete: true
        })
        
        form_submission.update(current_step_id: 'education')
      end
      
      it "redirects to the previous step" do
        patch :update, params: {
          id: form_submission.id,
          step_id: 'education',
          commit: 'Previous'
        }
        
        expect(response).to redirect_to(form_submission_path(step_id: 'personal_info'))
      end
    end
  end
end
require 'rails_helper'

describe FormSubmission, type: :model do
  it 'can be created with a session_id' do
    form_submission = FormSubmission.create(session_id: 'test-session-id')
    expect(form_submission).to be_valid
    expect(form_submission.session_id).to eq('test-session-id')
  end
end
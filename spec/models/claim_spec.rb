require 'rails_helper'

RSpec.describe Claim, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:tracking_id) }
    it { should validate_uniqueness_of(:tracking_id) }
    it { should validate_presence_of(:submission_date) }
    it { should validate_presence_of(:collection_key) }
    it { should validate_presence_of(:language) }
  end

  describe 'associations' do
    it { should have_one(:claimant).dependent(:destroy) }
    it { should have_one(:requirements).dependent(:destroy) }
    it { should have_one(:consents).dependent(:destroy) }
    it { should have_one(:residence_history).dependent(:destroy) }
    it { should have_one(:employment_history).dependent(:destroy) }
    it { should have_one(:education).dependent(:destroy) }
    it { should have_one(:professional_licenses).dependent(:destroy) }
    it { should have_one(:signature).dependent(:destroy) }
  end

  describe '#set_requirements_from_collection_key' do
    let(:claim) { build(:claim, collection_key: 'en-EPA-DTB-R3-E3-E-P-W') }

    it 'creates requirements based on collection key' do
      expect(claim.requirements).to be_nil
      claim.valid?
      expect(claim.requirements).not_to be_nil
      
      # Check consents required
      expect(claim.requirements.consents_required['driver_license']).to be true
      expect(claim.requirements.consents_required['drug_test']).to be true
      expect(claim.requirements.consents_required['biometric']).to be true
      
      # Check verification steps
      expect(claim.requirements.verification_steps['residence_history']['enabled']).to be true
      expect(claim.requirements.verification_steps['residence_history']['years']).to eq 3
      expect(claim.requirements.verification_steps['employment_history']['enabled']).to be true
      expect(claim.requirements.verification_steps['employment_history']['mode']).to eq 'years'
      expect(claim.requirements.verification_steps['employment_history']['years']).to eq 3
      expect(claim.requirements.verification_steps['education']['enabled']).to be true
      expect(claim.requirements.verification_steps['professional_license']['enabled']).to be true
    end
  end

  describe '#to_json_document' do
    let(:claim) { create(:claim_with_all_data) }

    it 'generates a complete JSON document' do
      json = claim.to_json_document
      
      expect(json[:metadata][:trackingId]).to eq claim.tracking_id
      expect(json[:metadata][:submissionDate]).to eq claim.submission_date.iso8601
      expect(json[:metadata][:version]).to eq '1.0'
      
      expect(json[:personalInfo]).not_to be_nil
      expect(json[:residenceHistory]).not_to be_empty
      expect(json[:employmentHistory]).not_to be_empty
      expect(json[:education]).not_to be_nil
      expect(json[:professionalLicenses]).not_to be_empty
      expect(json[:consents]).not_to be_nil
      expect(json[:signature]).not_to be_nil
    end
  end
end
require 'rails_helper'

RSpec.describe FormSubmission, type: :model do
  describe 'validations' do
    it 'validates current_step_id is in FormConfig.step_ids' do
      submission = FormSubmission.new(current_step_id: 'invalid_step')
      expect(submission).not_to be_valid
      expect(submission.errors[:current_step_id]).to include('is not included in the list')
    end

    it 'allows current_step_id to be nil' do
      submission = FormSubmission.new(current_step_id: nil)
      submission.valid?
      expect(submission.errors[:current_step_id]).to be_empty
    end
  end

  describe 'initialization' do
    it 'initializes with default values' do
      submission = FormSubmission.new
      
      expect(submission.steps).to be_a(Hash)
      expect(submission.steps.keys).to match_array(FormConfig.step_ids)
      
      FormConfig.step_ids.each do |step_id|
        expect(submission.steps[step_id]).to include(
          values: {},
          errors: {},
          is_valid: false,
          is_complete: false,
          touched: [],
          _config: {}
        )
      end
      
      expect(submission.current_step_id).to eq(FormConfig.step_ids.first)
    end
  end

  describe 'instance methods' do
    let(:submission) { FormSubmission.new }
    
    before do
      submission.steps['personal_info'] = {
        values: { 'name' => 'John Doe', 'email' => 'john@example.com' },
        errors: { 'phone' => 'is required' },
        is_valid: false,
        is_complete: false,
        touched: ['name', 'email'],
        _config: { 'require_phone' => true }
      }
    end
    
    describe '#step_state' do
      it 'returns the state for a step' do
        state = submission.step_state('personal_info')
        expect(state).to include(
          values: { 'name' => 'John Doe', 'email' => 'john@example.com' },
          errors: { 'phone' => 'is required' }
        )
      end
      
      it 'returns an empty hash for an unknown step' do
        state = submission.step_state('unknown_step')
        expect(state).to eq({})
      end
    end
    
    describe '#step_values' do
      it 'returns the values for a step' do
        values = submission.step_values('personal_info')
        expect(values).to eq({ 'name' => 'John Doe', 'email' => 'john@example.com' })
      end
      
      it 'returns an empty hash for an unknown step' do
        values = submission.step_values('unknown_step')
        expect(values).to eq({})
      end
    end
    
    describe '#step_errors' do
      it 'returns the errors for a step' do
        errors = submission.step_errors('personal_info')
        expect(errors).to eq({ 'phone' => 'is required' })
      end
      
      it 'returns an empty hash for an unknown step' do
        errors = submission.step_errors('unknown_step')
        expect(errors).to eq({})
      end
    end
    
    describe '#step_valid?' do
      it 'returns whether a step is valid' do
        expect(submission.step_valid?('personal_info')).to be_falsey
      end
      
      it 'returns false for an unknown step' do
        expect(submission.step_valid?('unknown_step')).to be_falsey
      end
    end
    
    describe '#step_complete?' do
      it 'returns whether a step is complete' do
        expect(submission.step_complete?('personal_info')).to be_falsey
      end
      
      it 'returns false for an unknown step' do
        expect(submission.step_complete?('unknown_step')).to be_falsey
      end
    end
    
    describe '#step_config' do
      it 'returns the config for a step' do
        config = submission.step_config('personal_info')
        expect(config).to eq({ 'require_phone' => true })
      end
      
      it 'returns an empty hash for an unknown step' do
        config = submission.step_config('unknown_step')
        expect(config).to eq({})
      end
    end
    
    describe '#touched_fields' do
      it 'returns the touched fields for a step' do
        touched = submission.touched_fields('personal_info')
        expect(touched).to eq(['name', 'email'])
      end
      
      it 'returns an empty array for an unknown step' do
        touched = submission.touched_fields('unknown_step')
        expect(touched).to eq([])
      end
    end
    
    describe '#update_step_state' do
      it 'updates the state for a step' do
        submission.update_step_state('personal_info', { is_valid: true, is_complete: true })
        
        expect(submission.step_valid?('personal_info')).to be_truthy
        expect(submission.step_complete?('personal_info')).to be_truthy
      end
    end
    
    describe '#move_to_step' do
      it 'updates the current_step_id for a valid step' do
        expect(submission.move_to_step('education')).to be_truthy
        expect(submission.current_step_id).to eq('education')
      end
      
      it 'returns false for an invalid step' do
        expect(submission.move_to_step('invalid_step')).to be_falsey
        expect(submission.current_step_id).to eq(FormConfig.step_ids.first)
      end
    end
    
    describe '#completed_steps' do
      it 'returns an array of completed step IDs' do
        submission.update_step_state('personal_info', { is_complete: true })
        submission.update_step_state('education', { is_complete: true })
        
        expect(submission.completed_steps).to contain_exactly('personal_info', 'education')
      end
    end
    
    describe '#complete?' do
      it 'returns true when all steps are complete' do
        FormConfig.step_ids.each do |step_id|
          submission.update_step_state(step_id, { is_complete: true })
        end
        
        expect(submission.complete?).to be_truthy
      end
      
      it 'returns false when not all steps are complete' do
        submission.update_step_state('personal_info', { is_complete: true })
        
        expect(submission.complete?).to be_falsey
      end
    end
  end
end
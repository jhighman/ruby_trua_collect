require 'rails_helper'

RSpec.describe Task, type: :model do
  # Validations
  it { should validate_presence_of(:title) }
  
  # Associations (for future expansion)
  # it { should belong_to(:user) }
  
  # Factory
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:task)).to be_valid
    end
  end
  
  # Instance methods
  describe '#complete?' do
    it 'returns true when completed_at is present' do
      task = build(:task, completed_at: Time.current)
      expect(task.complete?).to be true
    end
    
    it 'returns false when completed_at is nil' do
      task = build(:task, completed_at: nil)
      expect(task.complete?).to be false
    end
  end
  
  describe '#complete!' do
    it 'sets completed_at to current time' do
      task = create(:task, completed_at: nil)
      expect { task.complete! }.to change { task.completed_at }.from(nil).to(be_present)
    end
  end
  
  describe '#incomplete!' do
    it 'sets completed_at to nil' do
      task = create(:task, completed_at: Time.current)
      expect { task.incomplete! }.to change { task.completed_at }.to(nil)
    end
  end
end
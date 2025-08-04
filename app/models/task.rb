class Task < ApplicationRecord
  # Validations
  validates :title, presence: true
  
  # Instance methods
  def complete?
    completed_at.present?
  end
  
  def complete!
    update(completed_at: Time.current)
  end
  
  def incomplete!
    update(completed_at: nil)
  end
end

class User < ApplicationRecord
  # Relationships
  has_many :form_submissions, dependent: :destroy
  
  # Validations
  validates :email, presence: true, uniqueness: true
end
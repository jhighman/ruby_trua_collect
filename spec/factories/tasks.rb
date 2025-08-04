FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    description { "This is a sample task description" }
    completed_at { nil }
  end
end
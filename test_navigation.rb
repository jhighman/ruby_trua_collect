# Simple test script to verify the navigation flow of the form wizard
# This script doesn't rely on RSpec and can be run with `ruby test_navigation.rb`

require_relative 'config/environment'

puts "Starting navigation flow test..."

# Create a requirements config
requirements_config = RequirementsConfig.create(
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
)

# Create a form submission
form_submission = FormSubmission.create(requirements_config: requirements_config)
puts "Created form submission with ID: #{form_submission.id}"

# Test 1: Update personal_info step and verify it's marked as complete
puts "\nTest 1: Update personal_info step"
form_submission.update_step_state('personal_info', {
  values: { 'name' => 'Test User', 'email' => 'test@example.com' },
  is_valid: true,
  is_complete: true
})
form_submission.reload

if form_submission.step_complete?('personal_info')
  puts "✅ personal_info step is marked as complete"
else
  puts "❌ personal_info step is NOT marked as complete"
end

# Test 2: Verify that the next step is education
puts "\nTest 2: Verify next step is education"
form_state = FormStateService.new(form_submission)
next_step = FormConfig.step_ids[FormConfig.step_ids.index('personal_info') + 1]

if next_step == 'education'
  puts "✅ Next step is education"
else
  puts "❌ Next step is #{next_step}, expected education"
end

# Test 3: Update education step and verify it's marked as complete
puts "\nTest 3: Update education step"
form_submission.update_step_state('education', {
  values: { 'highest_level' => 'high_school' },
  is_valid: true,
  is_complete: true
})
form_submission.reload

if form_submission.step_complete?('education')
  puts "✅ education step is marked as complete"
else
  puts "❌ education step is NOT marked as complete"
end

# Test 4: Verify that the next step is residence_history
puts "\nTest 4: Verify next step is residence_history"
next_step = FormConfig.step_ids[FormConfig.step_ids.index('education') + 1]

if next_step == 'residence_history'
  puts "✅ Next step is residence_history"
else
  puts "❌ Next step is #{next_step}, expected residence_history"
end

# Test 5: Verify that we can navigate back to personal_info
puts "\nTest 5: Verify navigation back to personal_info"
prev_step = FormConfig.step_ids[FormConfig.step_ids.index('education') - 1]

if prev_step == 'personal_info'
  puts "✅ Previous step is personal_info"
else
  puts "❌ Previous step is #{prev_step}, expected personal_info"
end

puts "\nNavigation flow test completed."
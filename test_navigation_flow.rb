# Simple test script to verify the navigation flow of the form wizard
# This script doesn't rely on RSpec and can be run with `ruby test_navigation_flow.rb`

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

# Test 1: Verify that the first step is personal_info
puts "\nTest 1: Verify first step is personal_info"
first_step = FormConfig.step_ids.first

if first_step == 'personal_info'
  puts "✅ First step is personal_info"
else
  puts "❌ First step is #{first_step}, expected personal_info"
end

# Test 2: Verify that the next step after personal_info is education
puts "\nTest 2: Verify next step after personal_info is education"
next_step = FormConfig.step_ids[FormConfig.step_ids.index('personal_info') + 1]

if next_step == 'education'
  puts "✅ Next step after personal_info is education"
else
  puts "❌ Next step after personal_info is #{next_step}, expected education"
end

# Test 3: Verify that the next step after education is residence_history
puts "\nTest 3: Verify next step after education is residence_history"
next_step = FormConfig.step_ids[FormConfig.step_ids.index('education') + 1]

if next_step == 'residence_history'
  puts "✅ Next step after education is residence_history"
else
  puts "❌ Next step after education is #{next_step}, expected residence_history"
end

# Test 4: Verify that the previous step before education is personal_info
puts "\nTest 4: Verify previous step before education is personal_info"
prev_step = FormConfig.step_ids[FormConfig.step_ids.index('education') - 1]

if prev_step == 'personal_info'
  puts "✅ Previous step before education is personal_info"
else
  puts "❌ Previous step before education is #{prev_step}, expected personal_info"
end

# Test 5: Verify that the previous step before residence_history is education
puts "\nTest 5: Verify previous step before residence_history is education"
prev_step = FormConfig.step_ids[FormConfig.step_ids.index('residence_history') - 1]

if prev_step == 'education'
  puts "✅ Previous step before residence_history is education"
else
  puts "❌ Previous step before residence_history is #{prev_step}, expected education"
end

puts "\nNavigation flow test completed."
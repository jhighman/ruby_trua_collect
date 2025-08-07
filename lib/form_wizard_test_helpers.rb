# frozen_string_literal: true

module FormWizardTestHelpers
  # Create a test form submission
  def create_test_form_submission(options = {})
    # Create a requirements config if needed
    requirements_config = options[:requirements_config] || create_test_requirements_config

    # Create a user if needed and if user_id is provided
    user = options[:user] || (options[:user_id] ? User.find_by(id: options[:user_id]) : nil)

    # Create the form submission
    FormSubmission.create!(
      requirements_config: requirements_config,
      user: user,
      current_step_id: options[:current_step_id] || 'personal_info',
      session_id: options[:session_id] || SecureRandom.uuid,
      steps: options[:steps] || {},
      navigation_state: options[:navigation_state] || {},
      dynamic_steps: options[:dynamic_steps] || {},
      workflows: options[:workflows] || {},
      webhooks: options[:webhooks] || [],
      api_keys: options[:api_keys] || {},
      oauth_tokens: options[:oauth_tokens] || {},
      callbacks: options[:callbacks] || {},
      navigation_order: options[:navigation_order] || []
    )
  end

  # Create a test requirements config
  def create_test_requirements_config(options = {})
    RequirementsConfig.create!(
      consents_required: options[:consents_required] || {
        'terms' => true,
        'privacy' => true,
        'marketing' => false
      },
      signature: options[:signature] || {
        'required' => true
      },
      verification_steps: options[:verification_steps] || {
        'personalInfo' => { 'enabled' => true },
        'residenceHistory' => { 'enabled' => true },
        'employmentHistory' => { 'enabled' => true },
        'education' => { 'enabled' => true },
        'professionalLicense' => { 'enabled' => false }
      }
    )
  end

  # Fill a step with test data
  def fill_step_with_test_data(form_submission, step_id, test_data = {})
    # Get the form state service
    form_state = FormStateService.new(form_submission)

    # Update the step with test data
    form_state.update_step(step_id, test_data)

    # Reload the form submission
    form_submission.reload
  end

  # Complete a step with test data
  def complete_step_with_test_data(form_submission, step_id, test_data = {})
    # Get the form state service
    form_state = FormStateService.new(form_submission)

    # Get the step configuration
    step_config = FormConfig.find_step(step_id)
    return false unless step_config

    # Generate test data for required fields if not provided
    required_fields = step_config[:fields].select { |f| f[:required] }.map { |f| f[:id] }
    required_fields.each do |field_id|
      next if test_data.key?(field_id)

      # Generate test data based on field type
      test_data[field_id] = generate_test_data_for_field(step_config[:fields].find { |f| f[:id] == field_id })
    end

    # For accumulator steps, generate test entries if not provided
    if %w[residence_history employment_history education].include?(step_id) && !test_data.key?('entries')
      test_data['entries'] = generate_test_entries_for_step(step_id)
    end

    # Update the step with test data
    form_state.update_step(step_id, test_data)

    # Reload the form submission
    form_submission.reload
  end

  # Complete all steps with test data
  def complete_all_steps_with_test_data(form_submission)
    # Get the navigation service
    navigation = form_submission.navigation

    # Get all available steps
    available_steps = navigation.available_steps

    # Complete each step
    available_steps.each do |step_id|
      complete_step_with_test_data(form_submission, step_id)
    end

    # Reload the form submission
    form_submission.reload
  end

  # Navigate to the next step
  def navigate_to_next_step(form_submission, user_id = nil)
    # Get the navigation service
    navigation = form_submission.navigation

    # Navigate to the next step
    navigation.navigate_to_next(user_id)

    # Reload the form submission
    form_submission.reload
  end

  # Navigate to a specific step
  def navigate_to_step(form_submission, step_id, user_id = nil)
    # Get the navigation service
    navigation = form_submission.navigation

    # Navigate to the step
    navigation.navigate_to_step(step_id, user_id)

    # Reload the form submission
    form_submission.reload
  end

  # Test conditional logic
  def test_conditional_logic(form_submission, step_id, field_id, conditions)
    # Get the conditional logic service
    conditional_logic = form_submission.conditional_logic

    # Evaluate the conditions
    conditional_logic.evaluate_field_conditions(step_id, field_id, conditions)
  end

  # Test dynamic step generation
  def test_dynamic_step_generation(form_submission, template_id, params = {})
    # Get the dynamic step service
    dynamic_steps = form_submission.dynamic_steps_service

    # Generate the step
    dynamic_steps.generate_step(template_id, params)
  end

  # Test multi-path workflow
  def test_multi_path_workflow(form_submission, workflow_id, paths)
    # Get the multi-path workflow service
    workflow = form_submission.workflow

    # Define the workflow
    workflow.define_workflow(workflow_id, paths)

    # Determine the path
    workflow.determine_path(workflow_id)
  end

  # Test file upload
  def test_file_upload(form_submission, step_id, field_id, file, user_id = nil)
    # Get the file upload service
    file_upload = form_submission.file_upload

    # Process the upload
    file_upload.process_upload(step_id, field_id, file, user_id)
  end

  # Test integration
  def test_integration(form_submission, system, options = {})
    # Get the integration service
    integration = form_submission.integration

    # Export data to the system
    integration.export_data(system, options)
  end

  private

  # Generate test data for a field
  def generate_test_data_for_field(field)
    return nil unless field

    case field[:type]
    when 'text'
      "Test #{field[:label]}"
    when 'email'
      "test_#{SecureRandom.hex(4)}@example.com"
    when 'select'
      field[:options]&.first&.dig(:value) || 'test_option'
    when 'checkbox'
      true
    when 'radio'
      field[:options]&.first&.dig(:value) || 'test_option'
    when 'date'
      Date.current.iso8601
    when 'textarea'
      "Test #{field[:label]} with multiple lines.\nThis is a second line."
    when 'number'
      42
    when 'phone'
      '555-123-4567'
    when 'file'
      nil # Files need to be handled separately
    else
      'test_value'
    end
  end

  # Generate test entries for an accumulator step
  def generate_test_entries_for_step(step_id)
    case step_id
    when 'residence_history'
      generate_test_residence_entries
    when 'employment_history'
      generate_test_employment_entries
    when 'education'
      generate_test_education_entries
    else
      []
    end
  end

  # Generate test residence entries
  def generate_test_residence_entries
    # Generate entries covering the past 7 years
    entries = []
    
    # Current residence
    entries << {
      'address' => '123 Current St',
      'city' => 'Currentville',
      'state' => 'CA',
      'zip' => '12345',
      'start_date' => (Date.current - 2.years).iso8601,
      'end_date' => nil,
      'is_current' => true
    }
    
    # Previous residence
    entries << {
      'address' => '456 Previous Ave',
      'city' => 'Previoustown',
      'state' => 'NY',
      'zip' => '67890',
      'start_date' => (Date.current - 5.years).iso8601,
      'end_date' => (Date.current - 2.years - 1.day).iso8601,
      'is_current' => false
    }
    
    # Earlier residence
    entries << {
      'address' => '789 Earlier Blvd',
      'city' => 'Earlierville',
      'state' => 'TX',
      'zip' => '54321',
      'start_date' => (Date.current - 8.years).iso8601,
      'end_date' => (Date.current - 5.years - 1.day).iso8601,
      'is_current' => false
    }
    
    entries
  end

  # Generate test employment entries
  def generate_test_employment_entries
    # Generate entries covering the past 7 years
    entries = []
    
    # Current employment
    entries << {
      'employer' => 'Current Company',
      'title' => 'Senior Developer',
      'city' => 'Currentville',
      'state' => 'CA',
      'start_date' => (Date.current - 3.years).iso8601,
      'end_date' => nil,
      'is_current' => true
    }
    
    # Previous employment
    entries << {
      'employer' => 'Previous Corp',
      'title' => 'Developer',
      'city' => 'Previoustown',
      'state' => 'NY',
      'start_date' => (Date.current - 6.years).iso8601,
      'end_date' => (Date.current - 3.years - 1.day).iso8601,
      'is_current' => false
    }
    
    # Earlier employment
    entries << {
      'employer' => 'Earlier Inc',
      'title' => 'Junior Developer',
      'city' => 'Earlierville',
      'state' => 'TX',
      'start_date' => (Date.current - 8.years).iso8601,
      'end_date' => (Date.current - 6.years - 1.day).iso8601,
      'is_current' => false
    }
    
    entries
  end

  # Generate test education entries
  def generate_test_education_entries
    entries = []
    
    # College education
    entries << {
      'institution' => 'Test University',
      'degree' => 'Bachelor of Science',
      'field_of_study' => 'Computer Science',
      'location' => 'Testville, CA',
      'start_date' => (Date.current - 8.years).iso8601,
      'end_date' => (Date.current - 4.years).iso8601,
      'is_current' => false
    }
    
    entries
  end
end
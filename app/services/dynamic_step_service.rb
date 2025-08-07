# frozen_string_literal: true

class DynamicStepService
  attr_reader :form_submission

  def initialize(form_submission)
    @form_submission = form_submission
  end

  # Generate a dynamic step based on user input
  def generate_step(template_id, params = {})
    # Get the step template
    template = get_step_template(template_id)
    return nil unless template

    # Generate the step ID
    step_id = generate_step_id(template_id, params)

    # Generate the step configuration
    step_config = generate_step_config(template, params)

    # Register the dynamic step
    register_dynamic_step(step_id, step_config)

    # Return the step ID
    step_id
  end

  # Get all dynamic steps for this form submission
  def get_dynamic_steps
    form_submission.dynamic_steps || {}
  end

  # Get a specific dynamic step
  def get_dynamic_step(step_id)
    dynamic_steps = get_dynamic_steps
    dynamic_steps[step_id]
  end

  # Check if a step is a dynamic step
  def is_dynamic_step?(step_id)
    get_dynamic_steps.key?(step_id)
  end

  # Remove a dynamic step
  def remove_dynamic_step(step_id)
    # Get current dynamic steps
    dynamic_steps = get_dynamic_steps

    # Remove the step
    dynamic_steps.delete(step_id)

    # Update the form submission
    form_submission.update(dynamic_steps: dynamic_steps)
  end

  # Generate a multi-path workflow based on user input
  def generate_workflow(workflow_id, params = {})
    # Get the workflow template
    workflow = get_workflow_template(workflow_id)
    return [] unless workflow

    # Generate the steps for this workflow
    steps = []

    workflow[:steps].each do |step_template|
      # Generate the step
      step_id = generate_step(step_template[:id], params)
      steps << step_id if step_id
    end

    # Return the generated step IDs
    steps
  end

  # Insert dynamic steps into the navigation flow
  def insert_dynamic_steps(insertion_point, step_ids)
    # Get the navigation service
    navigation = form_submission.navigation

    # Get the current available steps
    available_steps = navigation.available_steps

    # Find the insertion point
    insertion_index = available_steps.index(insertion_point)
    return false unless insertion_index

    # Insert the dynamic steps
    new_steps = available_steps.dup
    new_steps.insert(insertion_index + 1, *step_ids)

    # Update the form submission with the new navigation order
    form_submission.update(navigation_order: new_steps)

    true
  end

  # Get all available steps including dynamic steps
  def get_all_available_steps
    # Get the navigation service
    navigation = form_submission.navigation

    # Get the base available steps
    base_steps = navigation.available_steps

    # Get the dynamic steps
    dynamic_steps = get_dynamic_steps.keys

    # Combine and return
    if form_submission.navigation_order.present?
      # Use the custom navigation order if available
      form_submission.navigation_order
    else
      # Otherwise, append dynamic steps to the end
      base_steps + dynamic_steps
    end
  end

  private

  # Get a step template
  def get_step_template(template_id)
    # Check if the template exists in the configuration
    Rails.application.config.step_templates[template_id.to_sym]
  end

  # Get a workflow template
  def get_workflow_template(workflow_id)
    # Check if the workflow exists in the configuration
    Rails.application.config.workflow_templates[workflow_id.to_sym]
  end

  # Generate a unique step ID
  def generate_step_id(template_id, params)
    # Create a unique ID based on the template and params
    base_id = "dynamic_#{template_id}"
    
    if params[:id].present?
      # Use the provided ID if available
      "#{base_id}_#{params[:id]}"
    else
      # Generate a unique ID
      "#{base_id}_#{SecureRandom.hex(4)}"
    end
  end

  # Generate step configuration from a template
  def generate_step_config(template, params)
    # Start with a deep copy of the template
    config = deep_copy(template)

    # Apply parameter substitutions
    apply_params(config, params)

    # Return the generated configuration
    config
  end

  # Register a dynamic step
  def register_dynamic_step(step_id, step_config)
    # Get current dynamic steps
    dynamic_steps = get_dynamic_steps

    # Add the new step
    dynamic_steps[step_id] = step_config

    # Update the form submission
    form_submission.update(dynamic_steps: dynamic_steps)
  end

  # Deep copy an object
  def deep_copy(obj)
    Marshal.load(Marshal.dump(obj))
  end

  # Apply parameter substitutions to a configuration
  def apply_params(config, params)
    case config
    when Hash
      config.each do |key, value|
        config[key] = apply_params(value, params)
      end
    when Array
      config.map! { |item| apply_params(item, params) }
    when String
      # Replace placeholders with parameter values
      result = config.dup
      params.each do |key, value|
        placeholder = "{{#{key}}}"
        result = result.gsub(placeholder, value.to_s) if result.include?(placeholder)
      end
      result
    else
      config
    end
  end
end
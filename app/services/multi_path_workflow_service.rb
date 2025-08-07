# frozen_string_literal: true

class MultiPathWorkflowService
  attr_reader :form_submission

  def initialize(form_submission)
    @form_submission = form_submission
  end

  # Define a workflow with multiple paths
  def define_workflow(workflow_id, paths)
    # Get current workflows
    workflows = form_submission.workflows || {}

    # Add the workflow
    workflows[workflow_id] = {
      'paths' => paths,
      'current_path' => nil,
      'created_at' => Time.current.iso8601
    }

    # Update the form submission
    form_submission.update(workflows: workflows)

    true
  end

  # Get a workflow
  def get_workflow(workflow_id)
    # Get workflows
    workflows = form_submission.workflows || {}

    # Get the workflow
    workflows[workflow_id]
  end

  # Set the current path for a workflow
  def set_current_path(workflow_id, path_id, user_id = nil)
    # Get the workflow
    workflow = get_workflow(workflow_id)
    return false unless workflow

    # Get the path
    path = workflow['paths'][path_id]
    return false unless path

    # Get the old path
    old_path = workflow['current_path']

    # Set the current path
    workflow['current_path'] = path_id

    # Update the workflow
    workflows = form_submission.workflows || {}
    workflows[workflow_id] = workflow
    form_submission.update(workflows: workflows)

    # Log the path change for audit trail
    AuditService.log_change(
      form_submission,
      'workflow',
      "#{workflow_id}_current_path",
      old_path,
      path_id,
      user_id
    )

    true
  end

  # Get the current path for a workflow
  def get_current_path(workflow_id)
    # Get the workflow
    workflow = get_workflow(workflow_id)
    return nil unless workflow

    # Get the current path
    path_id = workflow['current_path']
    return nil unless path_id

    # Get the path
    workflow['paths'][path_id]
  end

  # Get the next step in the current path
  def get_next_step_in_path(workflow_id, current_step_id)
    # Get the current path
    path = get_current_path(workflow_id)
    return nil unless path

    # Get the steps in the path
    steps = path['steps']
    return nil unless steps.is_a?(Array)

    # Find the current step
    current_index = steps.index(current_step_id)
    return nil unless current_index

    # Get the next step
    next_index = current_index + 1
    return nil if next_index >= steps.length

    steps[next_index]
  end

  # Get the previous step in the current path
  def get_previous_step_in_path(workflow_id, current_step_id)
    # Get the current path
    path = get_current_path(workflow_id)
    return nil unless path

    # Get the steps in the path
    steps = path['steps']
    return nil unless steps.is_a?(Array)

    # Find the current step
    current_index = steps.index(current_step_id)
    return nil unless current_index && current_index > 0

    steps[current_index - 1]
  end

  # Determine the path based on form data
  def determine_path(workflow_id)
    # Get the workflow
    workflow = get_workflow(workflow_id)
    return nil unless workflow

    # Get all paths
    paths = workflow['paths']
    return nil unless paths.is_a?(Hash)

    # Evaluate each path's conditions
    paths.each do |path_id, path|
      # Skip paths without conditions
      next unless path['conditions'].present?

      # Evaluate the conditions
      if evaluate_conditions(path['conditions'])
        return path_id
      end
    end

    # If no conditions match, return the default path
    workflow['default_path']
  end

  # Navigate to the next step in the current path
  def navigate_to_next_in_path(workflow_id, current_step_id, user_id = nil)
    # Get the next step
    next_step = get_next_step_in_path(workflow_id, current_step_id)
    return nil unless next_step

    # Get the navigation service
    navigation = form_submission.navigation

    # Navigate to the next step
    navigation.navigate_to_step(next_step, user_id)
  end

  # Navigate to the previous step in the current path
  def navigate_to_previous_in_path(workflow_id, current_step_id, user_id = nil)
    # Get the previous step
    previous_step = get_previous_step_in_path(workflow_id, current_step_id)
    return nil unless previous_step

    # Get the navigation service
    navigation = form_submission.navigation

    # Navigate to the previous step
    navigation.navigate_to_step(previous_step, user_id)
  end

  # Check if a step is in the current path
  def is_step_in_current_path?(workflow_id, step_id)
    # Get the current path
    path = get_current_path(workflow_id)
    return false unless path

    # Get the steps in the path
    steps = path['steps']
    return false unless steps.is_a?(Array)

    # Check if the step is in the path
    steps.include?(step_id)
  end

  # Get all steps in the current path
  def get_steps_in_current_path(workflow_id)
    # Get the current path
    path = get_current_path(workflow_id)
    return [] unless path

    # Get the steps in the path
    path['steps'] || []
  end

  # Add a decision point to a workflow
  def add_decision_point(workflow_id, step_id, decisions)
    # Get the workflow
    workflow = get_workflow(workflow_id)
    return false unless workflow

    # Add the decision point
    decision_points = workflow['decision_points'] || {}
    decision_points[step_id] = decisions

    # Update the workflow
    workflow['decision_points'] = decision_points
    workflows = form_submission.workflows || {}
    workflows[workflow_id] = workflow
    form_submission.update(workflows: workflows)

    true
  end

  # Make a decision at a decision point
  def make_decision(workflow_id, step_id, decision_id, user_id = nil)
    # Get the workflow
    workflow = get_workflow(workflow_id)
    return false unless workflow

    # Get the decision point
    decision_points = workflow['decision_points'] || {}
    decisions = decision_points[step_id]
    return false unless decisions

    # Get the decision
    decision = decisions[decision_id]
    return false unless decision

    # Get the path for this decision
    path_id = decision['path']
    return false unless path_id

    # Set the current path
    set_current_path(workflow_id, path_id, user_id)

    # Get the next step in the new path
    next_step = decision['next_step'] || workflow['paths'][path_id]['steps'].first
    return false unless next_step

    # Get the navigation service
    navigation = form_submission.navigation

    # Navigate to the next step
    navigation.navigate_to_step(next_step, user_id)
  end

  private

  # Evaluate conditions
  def evaluate_conditions(conditions)
    # Create a conditional logic service
    conditional_logic = ConditionalLogicService.new(form_submission)

    # Evaluate the conditions
    conditional_logic.evaluate_conditions(conditions)
  end
end
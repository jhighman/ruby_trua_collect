# frozen_string_literal: true

class <%= class_name %>Config
  # Define the steps for the form wizard
  def self.step_ids
    @step_ids ||= [
<% options[:steps].each do |step_id| %>
      '<%= step_id %>',
<% end %>
<% options[:accumulator_steps].each do |step_id| %>
      '<%= step_id %>',
<% end %>
<% options[:conditional_steps].each do |step_id| %>
      '<%= step_id %>',
<% end %>
    ]
  end
  
  # Find a step by ID
  def self.find_step(step_id)
    case step_id
<% options[:steps].each do |step_id| %>
    when '<%= step_id %>'
      <%= step_id %>_step
<% end %>
<% options[:accumulator_steps].each do |step_id| %>
    when '<%= step_id %>'
      <%= step_id %>_step
<% end %>
<% options[:conditional_steps].each do |step_id| %>
    when '<%= step_id %>'
      <%= step_id %>_step
<% end %>
    else
      nil
    end
  end
  
<% options[:steps].each do |step_id| %>
  # Define the <%= step_id %> step
  def self.<%= step_id %>_step
    {
      id: '<%= step_id %>',
      title: '<%= step_id.titleize %>',
      description: 'Please provide your <%= step_id.humanize.downcase %>.',
      fields: [
        # Add fields for this step
        {
          id: 'field1',
          label: 'Field 1',
          type: 'text',
          required: true
        },
        {
          id: 'field2',
          label: 'Field 2',
          type: 'text',
          required: false
        }
      ]
    }
  end
  
<% end %>
<% options[:accumulator_steps].each do |step_id| %>
  # Define the <%= step_id %> step (accumulator step)
  def self.<%= step_id %>_step
    {
      id: '<%= step_id %>',
      title: '<%= step_id.titleize %>',
      description: 'Please provide your <%= step_id.humanize.downcase %>.',
      accumulator: true,
      fields: [
        # Add fields for this step
        {
          id: 'field1',
          label: 'Field 1',
          type: 'text',
          required: true
        },
        {
          id: 'field2',
          label: 'Field 2',
          type: 'text',
          required: false
        }
      ]
    }
  end
  
<% end %>
<% options[:conditional_steps].each do |step_id| %>
  # Define the <%= step_id %> step (conditional step)
  def self.<%= step_id %>_step
    {
      id: '<%= step_id %>',
      title: '<%= step_id.titleize %>',
      description: 'Please provide your <%= step_id.humanize.downcase %>.',
      conditions: {
        type: 'equals',
        field: 'some_step.some_field',
        value: 'some_value'
      },
      fields: [
        # Add fields for this step
        {
          id: 'field1',
          label: 'Field 1',
          type: 'text',
          required: true
        },
        {
          id: 'field2',
          label: 'Field 2',
          type: 'text',
          required: false
        }
      ]
    }
  end
  
<% end %>
<% if options[:multi_path] %>
  # Define the workflow paths
  def self.workflow_paths
    {
      default: {
        name: 'Default Path',
        steps: step_ids
      },
      alternative: {
        name: 'Alternative Path',
        steps: step_ids.reject { |step_id| step_id == '<%= options[:conditional_steps].first %>' }
      }
    }
  end
<% end %>
end
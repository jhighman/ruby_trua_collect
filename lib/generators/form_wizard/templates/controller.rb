# frozen_string_literal: true

class <%= class_name %>Controller < ApplicationController
  before_action :set_<%= file_name %>
  before_action :check_form_expiration, except: [:show, :complete]
  
  # GET /<%= file_name.pluralize %>
  def index
    @<%= file_name.pluralize %> = current_user&.<%= file_name.pluralize %> || []
  end
  
  # GET /<%= file_name.pluralize %>/:id
  def show
    # Get the step ID from params or use the current step
    @step_id = params[:step_id] || @<%= file_name %>.current_step_id
    
    # Initialize navigation service
    @navigation = @<%= file_name %>.navigation
    
    # Check if step exists
    unless <%= class_name %>Config.step_ids.include?(@step_id)
      redirect_to <%= file_name %>_path(step_id: <%= class_name %>Config.step_ids.first) and return
    end
    
    # Check if step is enabled based on requirements
    unless @navigation.is_step_enabled(@step_id)
      # Find the first enabled step
      enabled_step = @navigation.available_steps.first
      redirect_to <%= file_name %>_path(step_id: enabled_step) and return
    end
    
    # Get navigation state
    @navigation_state = @navigation.navigation_state(@step_id)
    
    # Get requirements
    @requirements = @<%= file_name %>.requirements_config
    
    # Initialize lazy loader
    @lazy_loader = LazyLoadingService.new(@<%= file_name %>)
    
    # Lazy load the step data
    @step_data = @lazy_loader.lazy_load_step(@step_id)
    
    # Render the step view
    render "#{file_name}/steps/#{@step_id}"
  end
  
  # PATCH /<%= file_name.pluralize %>/:id
  def update
    # First, update the current_step_id to match the step_id parameter
    # This ensures we're working with the correct step
    if @<%= file_name %>.current_step_id != params[:step_id]
      @<%= file_name %>.update!(current_step_id: params[:step_id])
      @<%= file_name %>.reload
    end
    
    @form_state = <%= class_name %>FormStateService.new(@<%= file_name %>)
    @navigation = @<%= file_name %>.navigation
    @step_id = params[:step_id]
    
    # Get form values from params
    values = params[:<%= file_name %>]&.to_unsafe_h || {}
    
    # Handle special cases for accumulator steps
    <% options[:accumulator_steps].each do |step_id| %>
    if @step_id == '<%= step_id %>' && params[:commit] == 'Add Entry'
      handle_<%= step_id %>_entry(values)
      redirect_to <%= file_name %>_path(step_id: @step_id), status: :see_other and return
    end
    <% end %>
    
    <% if options[:file_uploads] %>
    # Handle file uploads
    if params[:files].present?
      handle_file_upload(params[:files])
      redirect_to <%= file_name %>_path(step_id: @step_id), status: :see_other and return
    end
    <% end %>
    
    # Update step state
    @form_state.update_step(@step_id, values, current_user&.id)
    
    # Reload the form submission to ensure we have the latest data
    @<%= file_name %>.reload
    
    # Handle navigation
    if params[:commit] == 'Next'
      # Navigate to the next step
      next_step = @navigation.navigate_to_next(current_user&.id)
      
      if next_step
        redirect_to <%= file_name %>_path(step_id: next_step), status: :see_other and return
      else
        # No more steps, go to completion page
        redirect_to complete_<%= file_name %>_path, status: :see_other and return
      end
    elsif params[:commit] == 'Previous'
      # Navigate to the previous step
      prev_step = @navigation.navigate_to_previous(current_user&.id)
      
      if prev_step
        redirect_to <%= file_name %>_path(step_id: prev_step), status: :see_other and return
      else
        redirect_to <%= file_name %>_path(step_id: @step_id), status: :see_other and return
      end
    elsif params[:commit] == 'Save and Exit'
      # Save the current state and redirect to the dashboard
      @navigation.save_state
      redirect_to <%= file_name.pluralize %>_path, notice: 'Your progress has been saved. You can resume later.' and return
    else
      @navigation_state = @navigation.navigation_state(@step_id)
      render "<%= file_name %>/steps/#{@step_id}"
    end
  end
  
  # POST /<%= file_name.pluralize %>/:id/validate_step
  def validate_step
    @form_state = <%= class_name %>FormStateService.new(@<%= file_name %>)
    step_id = params[:step_id]
    values = params[:<%= file_name %>]&.to_unsafe_h || {}
    
    validation_result = @form_state.validate_step(step_id, values)
    render json: validation_result
  end
  
  # GET /<%= file_name.pluralize %>/:id/complete
  def complete
    @navigation = @<%= file_name %>.navigation
    
    # Reload the form submission to ensure we have the latest data
    @<%= file_name %>.reload
    
    # Check if all available steps are complete
    all_complete = @navigation.available_steps.all? { |step_id| @<%= file_name %>.step_complete?(step_id) }
    
    if all_complete
      # Process the completed form submission
      # This could involve creating a record or other processing
      render :<%= file_name %>/complete
    else
      # Find the first incomplete step
      incomplete_step = @navigation.first_incomplete_step
      redirect_to <%= file_name %>_path(step_id: incomplete_step || @navigation.available_steps.first)
    end
  end
  
  # GET /<%= file_name.pluralize %>/:id/resume
  def resume
    # Resume the form from the saved state
    step_id = @<%= file_name %>.resume
    
    # Redirect to the current step
    redirect_to <%= file_name %>_path(step_id: step_id)
  end
  
  # DELETE /<%= file_name.pluralize %>/:id
  def destroy
    @step_id = params[:step_id]
    entry_index = params[:entry_index].to_i
    
    # Get the current entries
    @form_state = <%= class_name %>FormStateService.new(@<%= file_name %>)
    current_values = @<%= file_name %>.step_values(@step_id) || {}
    current_entries = current_values['entries'] || []
    
    # Remove the entry at the specified index
    if entry_index < current_entries.length
      current_entries.delete_at(entry_index)
      
      # Update the step state
      new_values = current_values.merge('entries' => current_entries)
      @form_state.update_step(@step_id, new_values, current_user&.id)
    end
    
    # Redirect back to the step
    redirect_to <%= file_name %>_path(step_id: @step_id), status: :see_other
  end
  
  private
  
  <% options[:accumulator_steps].each do |step_id| %>
  # Handle <%= step_id %> entry
  def handle_<%= step_id %>_entry(values)
    # Extract entry fields
    entry = {}
    
    # Add fields based on step type
    case '<%= step_id %>'
    when 'residence_history'
      entry = {
        'address' => values['address'],
        'city' => values['city'],
        'state' => values['state'],
        'zip' => values['zip'],
        'start_date' => values['start_date'],
        'end_date' => values['is_current'] == '1' ? nil : values['end_date'],
        'is_current' => values['is_current'] == '1'
      }
    when 'employment_history'
      entry = {
        'employer' => values['employer'],
        'title' => values['title'],
        'city' => values['city'],
        'state' => values['state'],
        'start_date' => values['start_date'],
        'end_date' => values['is_current'] == '1' ? nil : values['end_date'],
        'is_current' => values['is_current'] == '1'
      }
    when 'education'
      entry = {
        'institution' => values['institution'],
        'degree' => values['degree'],
        'field_of_study' => values['field_of_study'],
        'location' => values['location'],
        'start_date' => values['start_date'],
        'end_date' => values['is_current'] == '1' ? nil : values['end_date'],
        'is_current' => values['is_current'] == '1'
      }
    end
    
    # Get current entries
    current_step = @<%= file_name %>.steps['<%= step_id %>'] || {}
    current_values = current_step['values'] || {}
    current_entries = current_values['entries'] || []
    
    # Add the new entry
    new_entries = current_entries + [entry]
    
    # Create a new values hash with the updated entries
    new_values = {}
    new_values['entries'] = new_entries
    
    # Update the step state
    @form_state.update_step('<%= step_id %>', new_values, current_user&.id)
  end
  <% end %>
  
  <% if options[:file_uploads] %>
  # Handle file upload
  def handle_file_upload(files)
    # Get the file upload service
    file_upload = @<%= file_name %>.file_upload
    
    # Process each file
    files.each do |field_id, file|
      file_upload.process_upload(@step_id, field_id, file, current_user&.id)
    end
  end
  <% end %>
  
  # Check if the form has expired
  def check_form_expiration
    # Check if the form has expired
    if @<%= file_name %>.expired?
      redirect_to <%= file_name.pluralize %>_path, alert: 'Your form has expired. Please start a new form.' and return
    end
  end
  
  # Set the form submission
  def set_<%= file_name %>
    if user_signed_in?
      # For authenticated users, find or create a form submission associated with the user
      @<%= file_name %> = current_user.<%= file_name.pluralize %>.find_by(id: session[:<%= file_name %>_id])
      
      if @<%= file_name %>.nil?
        @<%= file_name %> = current_user.<%= file_name.pluralize %>.find_or_create_by(id: params[:id])
      end
    else
      # For guests, use session to track the form submission
      
      # First try to find by session_id stored in the session
      if session[:<%= file_name %>_id].present?
        @<%= file_name %> = <%= class_name %>.find_by(session_id: session[:<%= file_name %>_id])
      end
      
      # If not found by session_id, try by ID parameter
      if @<%= file_name %>.nil? && params[:id].present?
        @<%= file_name %> = <%= class_name %>.find_by(id: params[:id])
      end
      
      if @<%= file_name %>.nil?
        # If form submission not found or no ID provided, create a new one
        @<%= file_name %> = <%= class_name %>.create(
          session_id: SecureRandom.uuid,
          current_step_id: <%= class_name %>Config.step_ids.first,
          requirements_config_id: RequirementsConfig.first.id
        )
        session[:<%= file_name %>_id] = @<%= file_name %>.session_id
      end
    end
    
    # Ensure requirements_config is set
    if params[:requirements_config_id].present?
      @<%= file_name %>.update(requirements_config_id: params[:requirements_config_id])
    elsif @<%= file_name %>.requirements_config.nil?
      @<%= file_name %>.update(requirements_config: RequirementsConfig.first_or_create)
    end
  end
end
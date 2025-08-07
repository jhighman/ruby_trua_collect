# frozen_string_literal: true

class FormWizardGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  
  class_option :steps, type: :array, default: [], desc: 'List of step IDs to include in the wizard'
  class_option :accumulator_steps, type: :array, default: [], desc: 'List of accumulator step IDs to include in the wizard'
  class_option :conditional_steps, type: :array, default: [], desc: 'List of conditional step IDs to include in the wizard'
  class_option :dynamic_steps, type: :boolean, default: false, desc: 'Include support for dynamic steps'
  class_option :multi_path, type: :boolean, default: false, desc: 'Include support for multi-path workflows'
  class_option :file_uploads, type: :boolean, default: false, desc: 'Include support for file uploads'
  class_option :integrations, type: :boolean, default: false, desc: 'Include support for integrations'
  
  def create_controller
    template 'controller.rb', "app/controllers/#{file_name}_controller.rb"
  end
  
  def create_model
    template 'model.rb', "app/models/#{file_name}.rb"
  end
  
  def create_views
    # Create base views
    template 'views/index.html.erb', "app/views/#{file_name}/index.html.erb"
    template 'views/show.html.erb', "app/views/#{file_name}/show.html.erb"
    template 'views/complete.html.erb', "app/views/#{file_name}/complete.html.erb"
    
    # Create step views
    options[:steps].each do |step_id|
      template 'views/steps/generic_step.html.erb', "app/views/#{file_name}/steps/#{step_id}.html.erb"
    end
    
    # Create accumulator step views
    options[:accumulator_steps].each do |step_id|
      template 'views/steps/accumulator_step.html.erb', "app/views/#{file_name}/steps/#{step_id}.html.erb"
    end
    
    # Create conditional step views
    options[:conditional_steps].each do |step_id|
      template 'views/steps/conditional_step.html.erb', "app/views/#{file_name}/steps/#{step_id}.html.erb"
    end
    
    # Create shared views
    template 'views/shared/navigation.html.erb', "app/views/#{file_name}/shared/_navigation.html.erb"
    template 'views/shared/progress.html.erb', "app/views/#{file_name}/shared/_progress.html.erb"
    template 'views/shared/errors.html.erb', "app/views/#{file_name}/shared/_errors.html.erb"
    
    # Create additional views based on options
    if options[:dynamic_steps]
      template 'views/shared/dynamic_step.html.erb', "app/views/#{file_name}/shared/_dynamic_step.html.erb"
    end
    
    if options[:multi_path]
      template 'views/shared/path_selection.html.erb', "app/views/#{file_name}/shared/_path_selection.html.erb"
    end
    
    if options[:file_uploads]
      template 'views/shared/file_upload.html.erb', "app/views/#{file_name}/shared/_file_upload.html.erb"
    end
  end
  
  def create_services
    # Create base services
    template 'services/form_state_service.rb', "app/services/#{file_name}_form_state_service.rb"
    template 'services/navigation_service.rb', "app/services/#{file_name}_navigation_service.rb"
    
    # Create additional services based on options
    if options[:dynamic_steps]
      template 'services/dynamic_step_service.rb', "app/services/#{file_name}_dynamic_step_service.rb"
    end
    
    if options[:multi_path]
      template 'services/multi_path_workflow_service.rb', "app/services/#{file_name}_multi_path_workflow_service.rb"
    end
    
    if options[:file_uploads]
      template 'services/file_upload_service.rb', "app/services/#{file_name}_file_upload_service.rb"
    end
    
    if options[:integrations]
      template 'services/integration_service.rb', "app/services/#{file_name}_integration_service.rb"
    end
  end
  
  def create_config
    template 'config/form_config.rb', "app/models/#{file_name}_config.rb"
    
    if options[:accumulator_steps].any?
      template 'config/accumulator_steps.rb', "config/initializers/#{file_name}_accumulator_steps.rb"
    end
    
    if options[:dynamic_steps]
      template 'config/step_templates.rb', "config/initializers/#{file_name}_step_templates.rb"
    end
    
    if options[:multi_path]
      template 'config/workflow_templates.rb', "config/initializers/#{file_name}_workflow_templates.rb"
    end
  end
  
  def create_migrations
    # Create base migration
    template 'migrations/create_form_submissions.rb', "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_create_#{table_name}.rb"
    
    # Create additional migrations based on options
    if options[:dynamic_steps] || options[:multi_path] || options[:file_uploads] || options[:integrations]
      template 'migrations/add_advanced_features.rb', "db/migrate/#{(Time.now.utc + 1).strftime('%Y%m%d%H%M%S')}_add_advanced_features_to_#{table_name}.rb"
    end
  end
  
  def create_routes
    route "resources :#{file_name.pluralize} do\n" \
          "    member do\n" \
          "      get :complete\n" \
          "      get :resume\n" \
          "      post :validate_step\n" \
          "    end\n" \
          "  end"
  end
  
  def create_tests
    template 'tests/model_test.rb', "test/models/#{file_name}_test.rb"
    template 'tests/controller_test.rb', "test/controllers/#{file_name}_controller_test.rb"
    template 'tests/system_test.rb', "test/system/#{file_name}_test.rb"
    
    # Create test helpers
    template 'tests/test_helpers.rb', "test/support/#{file_name}_test_helpers.rb"
  end
  
  private
  
  def table_name
    file_name.pluralize
  end
end
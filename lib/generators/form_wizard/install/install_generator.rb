# frozen_string_literal: true

module FormWizard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      class_option :steps, type: :array, default: ['personal_info', 'contact_details', 'review'], 
                   desc: 'List of steps to create'
      class_option :flow_name, type: :string, default: 'default', 
                   desc: 'Name of the flow to create'
      
      def create_migration
        template 'migration.rb', "db/migrate/#{timestamp}_create_form_submissions.rb"
      end
      
      def create_model
        template 'model.rb', 'app/models/form_submission.rb'
        template 'model_concern.rb', 'app/models/concerns/form_wizard/model.rb'
      end
      
      def create_controller
        template 'controller.rb', 'app/controllers/form_submissions_controller.rb'
        template 'controller_concern.rb', 'app/controllers/concerns/form_wizard/controller.rb'
      end
      
      def create_views
        template 'show.html.erb', 'app/views/form_wizard/show.html.erb'
        template 'complete.html.erb', 'app/views/form_wizard/complete.html.erb'
        
        # Create directory for step views
        empty_directory 'app/views/form_wizard/steps'
      end
      
      def create_assets
        template 'form_wizard.css', 'app/assets/stylesheets/form_wizard.css'
        template 'form_wizard.js', 'app/assets/javascripts/form_wizard.js'
      end
      
      def create_components
        # Base components
        template 'wizard_component.rb', 'app/components/form_wizard/wizard_component.rb'
        template 'wizard_component.html.erb', 'app/views/components/form_wizard/wizard_component.html.erb'
        template 'complete_component.rb', 'app/components/form_wizard/complete_component.rb'
        template 'complete_component.html.erb', 'app/views/components/form_wizard/complete_component.html.erb'
        
        # Field components
        template 'base_field_component.rb', 'app/components/form_wizard/fields/base_field_component.rb'
        template 'base_field_component.html.erb', 'app/views/components/form_wizard/fields/base_field_component.html.erb'
        template 'text_field_component.rb', 'app/components/form_wizard/fields/text_field_component.rb'
        template 'select_field_component.rb', 'app/components/form_wizard/fields/select_field_component.rb'
        template 'checkbox_field_component.rb', 'app/components/form_wizard/fields/checkbox_field_component.rb'
        template 'date_field_component.rb', 'app/components/form_wizard/fields/date_field_component.rb'
        template 'textarea_field_component.rb', 'app/components/form_wizard/fields/textarea_field_component.rb'
        template 'radio_field_component.rb', 'app/components/form_wizard/fields/radio_field_component.rb'
      end
      
      def create_steps
        options[:steps].each do |step_name|
          @step_name = step_name
          @fields = default_fields_for_step(step_name)
          
          template 'step.rb', "app/steps/#{step_name}_step.rb"
          template 'step.html.erb', "app/views/form_wizard/steps/#{step_name}.html.erb"
        end
      end
      
      def create_flow
        @flow_name = options[:flow_name]
        @steps = options[:steps]
        
        template 'flow.rb', "app/flows/#{@flow_name}_flow.rb"
      end
      
      def create_directories
        empty_directory 'app/steps'
        empty_directory 'app/flows'
        empty_directory 'app/components/form_wizard'
        empty_directory 'app/components/form_wizard/fields'
        empty_directory 'app/views/components/form_wizard'
        empty_directory 'app/views/components/form_wizard/fields'
      end
      
      def update_routes
        route_file = 'config/routes.rb'
        routes_content = File.read(find_in_source_paths('routes.rb'))
        
        inject_into_file route_file, "  # Form Wizard routes\n", after: "Rails.application.routes.draw do\n"
        inject_into_file route_file, "  #{routes_content}\n", after: "  # Form Wizard routes\n"
      end
      
      def create_readme
        template 'README.md', 'README.form_wizard.md'
      end
      
      private
      
      def timestamp
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      end
      
      def default_fields_for_step(step_name)
        case step_name
        when 'personal_info'
          [
            { name: 'first_name', type: 'string', required: true, label: 'First Name' },
            { name: 'last_name', type: 'string', required: true, label: 'Last Name' },
            { name: 'date_of_birth', type: 'date', required: false, label: 'Date of Birth' }
          ]
        when 'contact_details'
          [
            { name: 'email', type: 'string', required: true, label: 'Email Address' },
            { name: 'phone', type: 'string', required: false, label: 'Phone Number' },
            { name: 'preferred_contact', type: 'select', required: true, label: 'Preferred Contact Method', options: "['Email', 'Phone']" }
          ]
        when 'review'
          [
            { name: 'terms_accepted', type: 'boolean', required: true, label: 'I accept the terms and conditions' }
          ]
        else
          [
            { name: 'field_one', type: 'string', required: true, label: 'Field One' },
            { name: 'field_two', type: 'string', required: false, label: 'Field Two' }
          ]
        end
      end
    end
  end
end
# frozen_string_literal: true

module FormWizard
  module Generators
    # Generator for creating a new form wizard step
    class StepGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      
      argument :fields, type: :array, default: [], banner: "field:type:required field:type:required"
      
      class_option :position, type: :numeric, default: nil, desc: "Position of the step in the flow"
      class_option :title, type: :string, default: nil, desc: "Title of the step"
      class_option :description, type: :string, default: nil, desc: "Description of the step"
      
      def create_step_file
        template "step.rb", "app/steps/#{file_name}_step.rb"
      end
      
      def create_view_file
        template "view.html.erb", "app/views/form_wizard/steps/#{file_name}.html.erb"
      end
      
      private
      
      def parse_fields
        fields.map do |field|
          parts = field.split(':')
          name = parts[0]
          type = parts[1] || 'string'
          required = parts[2] == 'required'
          
          { name: name, type: type, required: required }
        end
      end
      
      def step_title
        options[:title] || file_name.humanize
      end
      
      def step_description
        options[:description]
      end
      
      def step_position
        options[:position]
      end
    end
  end
end
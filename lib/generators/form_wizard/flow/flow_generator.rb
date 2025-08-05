# frozen_string_literal: true

module FormWizard
  module Generators
    # Generator for creating a new form wizard flow
    class FlowGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      
      argument :steps, type: :array, default: [], banner: "step1 step2 step3"
      
      class_option :description, type: :string, default: nil, desc: "Description of the flow"
      
      def create_flow_file
        template "flow.rb", "app/flows/#{file_name}_flow.rb"
      end
      
      private
      
      def flow_description
        options[:description] || "Flow for #{file_name.humanize}"
      end
      
      def flow_steps
        steps.empty? ? ["personal_info", "confirmation"] : steps
      end
    end
  end
end
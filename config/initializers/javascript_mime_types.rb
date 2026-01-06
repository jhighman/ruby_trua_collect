# Be sure to restart your server when you modify this file.

# Ensure JavaScript modules are served with the correct MIME type
require 'rack/mime'
Rack::Mime::MIME_TYPES['.js'] = 'application/javascript'
Rack::Mime::MIME_TYPES['.mjs'] = 'application/javascript+module'

# Register module MIME type
Mime::Type.register 'application/javascript+module', :module_js, ['application/javascript+module'], ['js', 'mjs']

# Add middleware to set correct MIME types for JavaScript files
Rails.application.config.middleware.insert_before 0, Rack::Rewrite do
  rewrite %r{^/assets/(.+\.js)$}, lambda { |match, rack_env|
    if rack_env['HTTP_ACCEPT']&.include?('module')
      rack_env['CONTENT_TYPE'] = 'application/javascript+module'
    else
      rack_env['CONTENT_TYPE'] = 'application/javascript'
    end
    "/assets/#{match[1]}"
  }
end

# Set proper MIME types for JavaScript files
Rails.application.config.action_dispatch.default_headers.merge!({
  'X-Content-Type-Options' => 'nosniff'
})

# Configure Rails to serve JavaScript with correct MIME type
Rails.application.config.middleware.use Rack::Static,
  urls: ["/javascript", "/app/javascript"],
  root: Rails.root.to_s,
  header_rules: [
    [%w(js), {'Content-Type' => 'application/javascript'}],
    [%w(mjs), {'Content-Type' => 'application/javascript+module'}]
  ]

# Ensure importmap serves JavaScript files with correct MIME type
Rails.application.config.after_initialize do
  Rails.application.config.assets.configure do |env|
    env.context_class.class_eval do
      def compute_asset_path(path, options = {})
        path = super
        if path.end_with?('.js')
          if options[:type] == :module
            path += "?type=module"
          else
            path += "?type=javascript"
          end
        end
        path
      end
    end
  end if defined?(Rails.application.config.assets)
end
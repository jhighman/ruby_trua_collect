# Be sure to restart your server when you modify this file.

# Custom middleware to set the correct MIME type for JavaScript files
class JavascriptMimeTypeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Check if the request is for a JavaScript file
    if env['PATH_INFO'] =~ /\.js$/
      # Set the Content-Type header to application/javascript
      env['HTTP_ACCEPT'] = 'application/javascript'
      
      # Check if this is a module request (from type="module")
      if env['HTTP_SEC_FETCH_DEST'] == 'script' || env['HTTP_ACCEPT']&.include?('module')
        env['HTTP_ACCEPT'] = 'application/javascript+module'
      end
    end

    # Call the next middleware in the stack
    status, headers, response = @app.call(env)

    # Set the Content-Type header for JavaScript files in the response
    if env['PATH_INFO'] =~ /\.js$/
      # Default to application/javascript
      content_type = 'application/javascript'
      
      # If the file is imported as a module, use the module MIME type
      if env['HTTP_SEC_FETCH_DEST'] == 'script' || env['HTTP_ACCEPT']&.include?('module')
        content_type = 'application/javascript+module'
      end
      
      headers['Content-Type'] = content_type
    end

    [status, headers, response]
  end
end

# Add the middleware to the Rails application
Rails.application.config.middleware.insert_before 0, JavascriptMimeTypeMiddleware
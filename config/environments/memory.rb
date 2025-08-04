require_relative "development"

Rails.application.configure do
  # Use the same settings as development, but with a few adjustments for in-memory database
  
  # Disable caching to ensure fresh data
  config.cache_classes = false
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  
  # Raise exceptions instead of rendering exception templates
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :none
  
  # Enable SQL query logging for debugging
  config.active_record.verbose_query_logs = true
  
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log
  
  # Configure ActiveRecord to use in-memory SQLite
  config.after_initialize do
    # Ensure schema is loaded into memory
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    
    # Create seed data if needed
    if defined?(Rails::Server)
      puts "Setting up in-memory database for testing..."
      
      # Create a sample claim for testing
      claim = Claim.create!(
        tracking_id: "TV-MEMORY-TEST",
        submission_date: nil,
        collection_key: "en-EPA-DTB-R5-E5-E-P-W",
        language: "en"
      )
      
      # Create a claimant
      claim.create_claimant!(
        full_name: "Test User",
        email: "test@example.com",
        phone: "555-123-4567",
        date_of_birth: 30.years.ago.to_date,
        ssn: "123-45-6789",
        completed_at: Time.current
      )
      
      puts "Sample data created successfully!"
    end
  end
end
# Configure the Rails cache store
Rails.application.configure do
  # Use memory store in development and test
  if Rails.env.development? || Rails.env.test?
    config.cache_store = :memory_store, { size: 64.megabytes }
  else
    # Use Redis cache store in production
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
      namespace: 'trua_collect',
      expires_in: 1.day
    }
  end
  
  # Enable fragment caching
  config.action_controller.perform_caching = true
end
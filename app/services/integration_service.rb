# frozen_string_literal: true

class IntegrationService
  attr_reader :form_submission

  def initialize(form_submission)
    @form_submission = form_submission
  end

  # Register a webhook for form events
  def register_webhook(url, events, secret = nil)
    # Get current webhooks
    webhooks = form_submission.webhooks || []

    # Create a new webhook
    webhook = {
      'id' => SecureRandom.uuid,
      'url' => url,
      'events' => events,
      'secret' => secret,
      'created_at' => Time.current.iso8601
    }

    # Add the webhook
    webhooks << webhook

    # Update the form submission
    form_submission.update(webhooks: webhooks)

    # Return the webhook ID
    webhook['id']
  end

  # Remove a webhook
  def remove_webhook(webhook_id)
    # Get current webhooks
    webhooks = form_submission.webhooks || []

    # Find the webhook
    webhook_index = webhooks.index { |w| w['id'] == webhook_id }
    return false unless webhook_index

    # Remove the webhook
    webhooks.delete_at(webhook_index)

    # Update the form submission
    form_submission.update(webhooks: webhooks)

    true
  end

  # Trigger webhooks for an event
  def trigger_webhooks(event, payload = {})
    # Get webhooks for this event
    webhooks = get_webhooks_for_event(event)
    return if webhooks.empty?

    # Prepare the payload
    full_payload = prepare_payload(event, payload)

    # Trigger each webhook
    webhooks.each do |webhook|
      trigger_webhook(webhook, full_payload)
    end
  end

  # Export form data to an external system
  def export_data(system, options = {})
    # Get the exporter for this system
    exporter = get_exporter(system)
    return { success: false, error: "Exporter not found for system: #{system}" } unless exporter

    # Export the data
    exporter.export(form_submission, options)
  end

  # Import data from an external system
  def import_data(system, options = {})
    # Get the importer for this system
    importer = get_importer(system)
    return { success: false, error: "Importer not found for system: #{system}" } unless importer

    # Import the data
    importer.import(form_submission, options)
  end

  # Register an API key for an external system
  def register_api_key(system, api_key, options = {})
    # Get current API keys
    api_keys = form_submission.api_keys || {}

    # Add the API key
    api_keys[system] = {
      'key' => api_key,
      'options' => options,
      'created_at' => Time.current.iso8601
    }

    # Update the form submission
    form_submission.update(api_keys: api_keys)

    true
  end

  # Get an API key for an external system
  def get_api_key(system)
    # Get API keys
    api_keys = form_submission.api_keys || {}

    # Get the API key
    api_key = api_keys[system]
    return nil unless api_key

    api_key['key']
  end

  # Register an OAuth token for an external system
  def register_oauth_token(system, token, refresh_token = nil, expires_at = nil, options = {})
    # Get current OAuth tokens
    oauth_tokens = form_submission.oauth_tokens || {}

    # Add the token
    oauth_tokens[system] = {
      'token' => token,
      'refresh_token' => refresh_token,
      'expires_at' => expires_at,
      'options' => options,
      'created_at' => Time.current.iso8601
    }

    # Update the form submission
    form_submission.update(oauth_tokens: oauth_tokens)

    true
  end

  # Get an OAuth token for an external system
  def get_oauth_token(system)
    # Get OAuth tokens
    oauth_tokens = form_submission.oauth_tokens || {}

    # Get the token
    token = oauth_tokens[system]
    return nil unless token

    # Check if the token has expired
    if token['expires_at'].present? && Time.parse(token['expires_at']) < Time.current
      # Try to refresh the token
      refreshed_token = refresh_oauth_token(system, token)
      return refreshed_token if refreshed_token

      # Token has expired and couldn't be refreshed
      return nil
    end

    token['token']
  end

  # Register a callback for an external system
  def register_callback(system, callback_url, options = {})
    # Get current callbacks
    callbacks = form_submission.callbacks || {}

    # Add the callback
    callbacks[system] = {
      'url' => callback_url,
      'options' => options,
      'created_at' => Time.current.iso8601
    }

    # Update the form submission
    form_submission.update(callbacks: callbacks)

    true
  end

  # Get a callback URL for an external system
  def get_callback_url(system)
    # Get callbacks
    callbacks = form_submission.callbacks || {}

    # Get the callback
    callback = callbacks[system]
    return nil unless callback

    callback['url']
  end

  private

  # Get webhooks for an event
  def get_webhooks_for_event(event)
    # Get all webhooks
    webhooks = form_submission.webhooks || []

    # Filter webhooks for this event
    webhooks.select do |webhook|
      webhook['events'].include?(event) || webhook['events'].include?('*')
    end
  end

  # Prepare the payload for a webhook
  def prepare_payload(event, payload)
    {
      'event' => event,
      'form_submission_id' => form_submission.id,
      'timestamp' => Time.current.iso8601,
      'data' => payload
    }
  end

  # Trigger a webhook
  def trigger_webhook(webhook, payload)
    # Add signature if a secret is provided
    headers = { 'Content-Type' => 'application/json' }
    
    if webhook['secret'].present?
      signature = generate_signature(payload.to_json, webhook['secret'])
      headers['X-Webhook-Signature'] = signature
    end

    # Send the webhook
    begin
      response = HTTParty.post(
        webhook['url'],
        body: payload.to_json,
        headers: headers
      )

      # Log the webhook
      log_webhook(webhook, payload, response)

      # Return the response
      {
        success: response.success?,
        status: response.code,
        body: response.body
      }
    rescue => e
      # Log the error
      log_webhook_error(webhook, payload, e)

      # Return the error
      {
        success: false,
        error: e.message
      }
    end
  end

  # Generate a signature for a webhook payload
  def generate_signature(payload, secret)
    OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
  end

  # Log a webhook
  def log_webhook(webhook, payload, response)
    AuditService.log_event(
      form_submission,
      'webhook',
      {
        webhook_id: webhook['id'],
        url: webhook['url'],
        event: payload['event'],
        status: response.code,
        success: response.success?
      }
    )
  end

  # Log a webhook error
  def log_webhook_error(webhook, payload, error)
    AuditService.log_event(
      form_submission,
      'webhook_error',
      {
        webhook_id: webhook['id'],
        url: webhook['url'],
        event: payload['event'],
        error: error.message
      }
    )
  end

  # Get an exporter for a system
  def get_exporter(system)
    # Get the exporter class
    exporter_class = "#{system.camelize}Exporter".constantize
    exporter_class.new
  rescue NameError
    nil
  end

  # Get an importer for a system
  def get_importer(system)
    # Get the importer class
    importer_class = "#{system.camelize}Importer".constantize
    importer_class.new
  rescue NameError
    nil
  end

  # Refresh an OAuth token
  def refresh_oauth_token(system, token)
    # Get the OAuth client for this system
    oauth_client = get_oauth_client(system)
    return nil unless oauth_client

    # Refresh the token
    begin
      new_token = oauth_client.refresh_token(token['refresh_token'])
      
      # Update the token
      register_oauth_token(
        system,
        new_token['access_token'],
        new_token['refresh_token'] || token['refresh_token'],
        Time.current + new_token['expires_in'].to_i.seconds,
        token['options']
      )
      
      new_token['access_token']
    rescue => e
      # Log the error
      AuditService.log_event(
        form_submission,
        'oauth_refresh_error',
        {
          system: system,
          error: e.message
        }
      )
      
      nil
    end
  end

  # Get an OAuth client for a system
  def get_oauth_client(system)
    # Get the OAuth client class
    client_class = "#{system.camelize}OAuthClient".constantize
    client_class.new
  rescue NameError
    nil
  end
end
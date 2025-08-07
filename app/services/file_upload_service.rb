# frozen_string_literal: true

class FileUploadService
  attr_reader :form_submission

  def initialize(form_submission)
    @form_submission = form_submission
  end

  # Process a file upload
  def process_upload(step_id, field_id, file, user_id = nil)
    # Validate the file
    validation_result = validate_file(step_id, field_id, file)
    return validation_result unless validation_result[:valid]

    # Generate a unique filename
    filename = generate_filename(file.original_filename)

    # Store the file
    stored_file = store_file(file, filename)

    # Update the form submission with the file metadata
    update_form_submission(step_id, field_id, stored_file, user_id)

    # Return success
    { valid: true, file: stored_file }
  end

  # Get file metadata for a specific field
  def get_file_metadata(step_id, field_id)
    # Get the step values
    step_values = form_submission.step_values(step_id) || {}

    # Get the file metadata
    step_values[field_id]
  end

  # Remove a file
  def remove_file(step_id, field_id, user_id = nil)
    # Get the file metadata
    file_metadata = get_file_metadata(step_id, field_id)
    return false unless file_metadata

    # Delete the file from storage
    delete_file(file_metadata)

    # Update the form submission
    update_form_submission(step_id, field_id, nil, user_id)

    true
  end

  # Generate a preview URL for a file
  def generate_preview_url(step_id, field_id)
    # Get the file metadata
    file_metadata = get_file_metadata(step_id, field_id)
    return nil unless file_metadata

    # Generate a preview URL
    if file_metadata['storage_type'] == 's3'
      # For S3 storage, generate a presigned URL
      s3_client = Aws::S3::Client.new
      signer = Aws::S3::Presigner.new(client: s3_client)
      
      signer.presigned_url(
        :get_object,
        bucket: file_metadata['bucket'],
        key: file_metadata['key'],
        expires_in: 3600 # URL expires in 1 hour
      )
    else
      # For local storage, use the file path
      "/uploads/#{file_metadata['filename']}"
    end
  end

  # Validate multiple files
  def validate_files(step_id, field_id, files)
    # Validate each file
    results = files.map do |file|
      validate_file(step_id, field_id, file)
    end

    # Check if all files are valid
    all_valid = results.all? { |result| result[:valid] }

    # Return the results
    {
      valid: all_valid,
      results: results
    }
  end

  private

  # Validate a file
  def validate_file(step_id, field_id, file)
    # Get the field configuration
    field_config = get_field_config(step_id, field_id)
    return { valid: false, error: 'Invalid field' } unless field_config

    # Get the validation rules
    validation = field_config[:file_validation] || {}

    # Check file size
    if validation[:max_size].present?
      max_size = validation[:max_size].to_i.megabytes
      if file.size > max_size
        return { valid: false, error: "File size exceeds the maximum allowed size of #{validation[:max_size]}MB" }
      end
    end

    # Check file type
    if validation[:allowed_types].present?
      allowed_types = validation[:allowed_types]
      content_type = file.content_type
      
      unless allowed_types.include?(content_type)
        return { valid: false, error: "File type #{content_type} is not allowed. Allowed types: #{allowed_types.join(', ')}" }
      end
    end

    # Check file extension
    if validation[:allowed_extensions].present?
      allowed_extensions = validation[:allowed_extensions]
      extension = File.extname(file.original_filename).delete('.').downcase
      
      unless allowed_extensions.include?(extension)
        return { valid: false, error: "File extension .#{extension} is not allowed. Allowed extensions: #{allowed_extensions.join(', ')}" }
      end
    end

    # Custom validation
    if validation[:custom_validation].present? && respond_to?(validation[:custom_validation], true)
      custom_result = send(validation[:custom_validation], file)
      return custom_result unless custom_result[:valid]
    end

    # All validations passed
    { valid: true }
  end

  # Get field configuration
  def get_field_config(step_id, field_id)
    # Get the step configuration
    step_config = FormConfig.find_step(step_id)
    return nil unless step_config

    # Find the field
    step_config[:fields]&.find { |f| f[:id] == field_id }
  end

  # Generate a unique filename
  def generate_filename(original_filename)
    # Extract the extension
    extension = File.extname(original_filename)
    base_name = File.basename(original_filename, extension)

    # Generate a unique name
    timestamp = Time.current.to_i
    random = SecureRandom.hex(4)
    
    "#{base_name}_#{timestamp}_#{random}#{extension}"
  end

  # Store a file
  def store_file(file, filename)
    # Determine storage type based on configuration
    storage_type = Rails.application.config.file_storage || 'local'

    if storage_type == 's3'
      # Store in S3
      store_file_in_s3(file, filename)
    else
      # Store locally
      store_file_locally(file, filename)
    end
  end

  # Store a file in S3
  def store_file_in_s3(file, filename)
    # Get S3 configuration
    s3_config = Rails.application.config.s3_config || {}
    bucket = s3_config[:bucket] || 'trua-collect-uploads'
    
    # Create S3 client
    s3_client = Aws::S3::Client.new
    
    # Upload the file
    key = "uploads/#{form_submission.id}/#{filename}"
    
    s3_client.put_object(
      bucket: bucket,
      key: key,
      body: file.read,
      content_type: file.content_type
    )
    
    # Return file metadata
    {
      'filename' => filename,
      'content_type' => file.content_type,
      'size' => file.size,
      'storage_type' => 's3',
      'bucket' => bucket,
      'key' => key,
      'uploaded_at' => Time.current.iso8601
    }
  end

  # Store a file locally
  def store_file_locally(file, filename)
    # Create the upload directory if it doesn't exist
    upload_dir = Rails.root.join('public', 'uploads', form_submission.id.to_s)
    FileUtils.mkdir_p(upload_dir)
    
    # Save the file
    file_path = upload_dir.join(filename)
    File.open(file_path, 'wb') do |f|
      f.write(file.read)
    end
    
    # Return file metadata
    {
      'filename' => filename,
      'content_type' => file.content_type,
      'size' => file.size,
      'storage_type' => 'local',
      'path' => file_path.to_s,
      'uploaded_at' => Time.current.iso8601
    }
  end

  # Delete a file
  def delete_file(file_metadata)
    if file_metadata['storage_type'] == 's3'
      # Delete from S3
      s3_client = Aws::S3::Client.new
      
      s3_client.delete_object(
        bucket: file_metadata['bucket'],
        key: file_metadata['key']
      )
    else
      # Delete from local storage
      File.delete(file_metadata['path']) if File.exist?(file_metadata['path'])
    end
  end

  # Update the form submission with file metadata
  def update_form_submission(step_id, field_id, file_metadata, user_id = nil)
    # Get the current step values
    form_state = FormStateService.new(form_submission)
    current_values = form_submission.step_values(step_id) || {}
    
    # Get the old file metadata for audit trail
    old_file_metadata = current_values[field_id]
    
    # Update the values
    new_values = current_values.merge(field_id => file_metadata)
    
    # Update the step state
    form_state.update_step(step_id, new_values, user_id)
    
    # Log the file upload/removal for audit trail
    if file_metadata.nil?
      AuditService.log_change(
        form_submission,
        step_id,
        field_id,
        old_file_metadata.to_json,
        "FILE REMOVED",
        user_id
      )
    else
      AuditService.log_change(
        form_submission,
        step_id,
        field_id,
        old_file_metadata.to_json,
        "FILE UPLOADED: #{file_metadata['filename']}",
        user_id
      )
    end
  end
end
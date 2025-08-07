namespace :form_submissions do
  desc "Clean up abandoned form submissions older than 24 hours"
  task cleanup: :environment do
    puts "Starting cleanup of abandoned form submissions..."
    
    # Find form submissions older than 24 hours
    cutoff_time = 1.day.ago
    abandoned_submissions = FormSubmission.where('created_at < ?', cutoff_time)
    
    # Count before deletion
    count = abandoned_submissions.count
    
    # Delete the abandoned submissions
    abandoned_submissions.delete_all
    
    puts "Cleanup complete. Deleted #{count} abandoned form submissions."
  end
end
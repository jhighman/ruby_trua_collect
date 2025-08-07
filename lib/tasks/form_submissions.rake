namespace :form_submissions do
  desc "Clean up expired form submissions"
  task cleanup_expired: :environment do
    # Default expiration time is 30 days
    expiration_days = ENV.fetch('FORM_EXPIRATION_DAYS', 30).to_i
    
    # Find form submissions that haven't been updated in the specified time
    cutoff_date = expiration_days.days.ago
    
    # Find expired form submissions
    expired_submissions = FormSubmission.where('last_active_at < ? OR (last_active_at IS NULL AND updated_at < ?)', 
                                              cutoff_date, cutoff_date)
                                       .where(completed: false)
    
    # Log the number of expired submissions
    puts "Found #{expired_submissions.count} expired form submissions"
    
    # Delete the expired submissions
    if expired_submissions.any?
      # Create audit logs for the deletions
      expired_submissions.find_each do |submission|
        AuditService.log_change(
          submission,
          'system',
          'status',
          'expired',
          'deleted',
          nil
        )
      end
      
      # Delete the submissions
      deleted_count = expired_submissions.delete_all
      puts "Deleted #{deleted_count} expired form submissions"
    else
      puts "No expired form submissions to delete"
    end
  end
  
  desc "Generate report on form submission activity"
  task activity_report: :environment do
    # Get counts for various metrics
    total_count = FormSubmission.count
    completed_count = FormSubmission.where(completed: true).count
    in_progress_count = total_count - completed_count
    
    # Get counts by step
    step_counts = {}
    FormSubmission.where(completed: false).group(:current_step_id).count.each do |step_id, count|
      step_counts[step_id] = count
    end
    
    # Get counts by day for the last 30 days
    daily_counts = {}
    30.downto(0) do |days_ago|
      date = days_ago.days.ago.to_date
      daily_counts[date] = FormSubmission.where('DATE(created_at) = ?', date).count
    end
    
    # Print the report
    puts "=== Form Submission Activity Report ==="
    puts "Total form submissions: #{total_count}"
    puts "Completed form submissions: #{completed_count}"
    puts "In-progress form submissions: #{in_progress_count}"
    puts
    puts "=== In-Progress Submissions by Step ==="
    step_counts.each do |step_id, count|
      puts "#{step_id}: #{count}"
    end
    puts
    puts "=== New Submissions by Day (Last 30 Days) ==="
    daily_counts.each do |date, count|
      puts "#{date}: #{count}"
    end
  end
end
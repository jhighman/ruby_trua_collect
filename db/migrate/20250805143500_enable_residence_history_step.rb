class EnableResidenceHistoryStep < ActiveRecord::Migration[8.0]
  def up
    # Get the first RequirementsConfig record
    config = RequirementsConfig.first
    
    if config
      # Get the current verification_steps
      verification_steps = config.verification_steps || {}
      
      # Enable residence history step
      verification_steps['residenceHistory'] = {
        'enabled' => true,
        'years' => 3
      }
      
      # Update the record
      config.update(verification_steps: verification_steps)
      
      puts "Residence history step enabled in RequirementsConfig"
    else
      puts "No RequirementsConfig found"
    end
  end

  def down
    # Get the first RequirementsConfig record
    config = RequirementsConfig.first
    
    if config
      # Get the current verification_steps
      verification_steps = config.verification_steps || {}
      
      # Disable residence history step
      if verification_steps['residenceHistory']
        verification_steps['residenceHistory']['enabled'] = false
      end
      
      # Update the record
      config.update(verification_steps: verification_steps)
      
      puts "Residence history step disabled in RequirementsConfig"
    else
      puts "No RequirementsConfig found"
    end
  end
end
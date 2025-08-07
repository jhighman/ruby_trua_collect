class EnableEducationStep < ActiveRecord::Migration[7.0]
  def up
    # Find all RequirementsConfig records
    RequirementsConfig.find_each do |config|
      # Get the current verification_steps
      verification_steps = config.verification_steps || {}
      
      # Enable the education step
      if verification_steps.key?('education')
        verification_steps['education']['enabled'] = true
      else
        verification_steps['education'] = { 'enabled' => true }
      end
      
      # Save the updated config
      config.update!(verification_steps: verification_steps)
    end
  end

  def down
    # Find all RequirementsConfig records
    RequirementsConfig.find_each do |config|
      # Get the current verification_steps
      verification_steps = config.verification_steps || {}
      
      # Disable the education step
      if verification_steps.key?('education')
        verification_steps['education']['enabled'] = false
      end
      
      # Save the updated config
      config.update!(verification_steps: verification_steps)
    end
  end
end
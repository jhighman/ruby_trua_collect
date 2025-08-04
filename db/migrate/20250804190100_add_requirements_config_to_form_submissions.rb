class AddRequirementsConfigToFormSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_reference :form_submissions, :requirements_config, foreign_key: true, index: true
  end
end
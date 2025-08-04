class CreateFormSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :form_submissions do |t|
      t.string :current_step_id
      t.json :steps, default: {}
      t.references :user, null: true, foreign_key: true
      t.string :session_id
      t.timestamps
    end
    
    add_index :form_submissions, :session_id
  end
end
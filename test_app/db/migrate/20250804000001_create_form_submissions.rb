class CreateFormSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :form_submissions do |t|
      t.string :session_id, null: false
      t.text :data
      t.string :current_step
      t.boolean :completed, default: false
      
      t.timestamps
    end
    
    add_index :form_submissions, :session_id, unique: true
  end
end
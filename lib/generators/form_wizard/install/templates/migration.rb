# frozen_string_literal: true

# Migration for creating form submissions table
class CreateFormSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :form_submissions do |t|
      t.string :current_step_id
      t.jsonb :steps, default: {}, null: false
      t.string :flow_name
      t.references :user, foreign_key: true, null: true
      t.datetime :submitted_at
      
      t.timestamps
    end
    
    add_index :form_submissions, :flow_name
    add_index :form_submissions, :submitted_at
  end
end
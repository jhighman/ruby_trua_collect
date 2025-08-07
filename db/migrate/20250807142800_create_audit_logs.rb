class CreateAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs do |t|
      t.references :form_submission, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :step_id, null: false
      t.string :field, null: false
      t.text :old_value
      t.text :new_value
      t.datetime :timestamp, null: false

      t.timestamps
    end
    
    add_index :audit_logs, [:form_submission_id, :step_id]
    add_index :audit_logs, [:form_submission_id, :timestamp]
  end
end
class Create<%= table_name.camelize %> < ActiveRecord::Migration[6.1]
  def change
    create_table :<%= table_name %> do |t|
      t.references :user, foreign_key: true, null: true
      t.references :requirements_config, foreign_key: true, null: true
      t.string :session_id
      t.string :current_step_id
      t.jsonb :steps, default: {}, null: false
      t.jsonb :navigation_state, default: {}, null: false
      t.datetime :last_active_at
      t.string :status, default: 'in_progress'

      t.timestamps
    end

    add_index :<%= table_name %>, :session_id
    add_index :<%= table_name %>, :current_step_id
    add_index :<%= table_name %>, :status
  end
end
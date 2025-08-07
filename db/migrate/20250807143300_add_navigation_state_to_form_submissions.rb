class AddNavigationStateToFormSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_column :form_submissions, :navigation_state, :text, default: "{}", null: false
    add_column :form_submissions, :last_active_at, :datetime
    add_index :form_submissions, :last_active_at
  end
end
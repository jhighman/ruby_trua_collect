class AddSubmittedAtToFormSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :form_submissions, :submitted_at, :datetime
    add_index :form_submissions, :submitted_at
  end
end
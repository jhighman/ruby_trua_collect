class AddAdvancedFeaturesToFormSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_column :form_submissions, :dynamic_steps, :text, default: "{}", null: false
    add_column :form_submissions, :workflows, :text, default: "{}", null: false
    add_column :form_submissions, :webhooks, :text, default: "[]", null: false
    add_column :form_submissions, :api_keys, :text, default: "{}", null: false
    add_column :form_submissions, :oauth_tokens, :text, default: "{}", null: false
    add_column :form_submissions, :callbacks, :text, default: "{}", null: false
    add_column :form_submissions, :navigation_order, :text, default: "[]", null: false
  end
end
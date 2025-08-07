class AddAdvancedFeaturesTo<%= table_name.camelize %> < ActiveRecord::Migration[6.1]
  def change
<% if options[:dynamic_steps] %>
    add_column :<%= table_name %>, :dynamic_steps, :jsonb, default: {}, null: false
<% end %>
<% if options[:multi_path] %>
    add_column :<%= table_name %>, :workflows, :jsonb, default: {}, null: false
    add_column :<%= table_name %>, :navigation_order, :jsonb, default: [], null: false
<% end %>
<% if options[:file_uploads] %>
    add_column :<%= table_name %>, :files, :jsonb, default: {}, null: false
<% end %>
<% if options[:integrations] %>
    add_column :<%= table_name %>, :webhooks, :jsonb, default: [], null: false
    add_column :<%= table_name %>, :api_keys, :jsonb, default: {}, null: false
    add_column :<%= table_name %>, :oauth_tokens, :jsonb, default: {}, null: false
    add_column :<%= table_name %>, :callbacks, :jsonb, default: {}, null: false
<% end %>
  end
end
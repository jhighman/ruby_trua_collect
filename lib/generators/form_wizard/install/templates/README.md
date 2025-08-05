# Form Wizard

The Form Wizard has been successfully installed! Here's what was created:

## Models

- `FormSubmission`: Stores the form data and state

## Controllers

- `FormSubmissionsController`: Handles form submissions and navigation

## Views

- `app/views/form_wizard/steps/`: Directory for step templates

## Steps

The following steps were created:

<% options[:steps].each do |step| %>
- `<%= step %>`: `app/steps/<%= step %>_step.rb` and `app/views/form_wizard/steps/<%= step %>.html.erb`
<% end %>

## Flow

- `<%= options[:flow_name] %>`: `app/flows/<%= options[:flow_name] %>_flow.rb`

## Routes

The following routes were added:

```ruby
get '/form', to: 'form_submissions#show', as: :form_submission
patch '/form', to: 'form_submissions#update'
post '/form/validate_step', to: 'form_submissions#validate_step', as: :validate_step_form_submission
get '/form/complete', to: 'form_submissions#complete', as: :complete_form_submission
```

## Next Steps

1. Run the migration to create the form submissions table:

```bash
rails db:migrate
```

2. Add authentication if needed:

```ruby
# In app/controllers/form_submissions_controller.rb
before_action :authenticate_user!
```

3. Customize the steps and flow as needed.

4. Add more steps:

```bash
rails generate form_wizard:step new_step field1:string:required field2:select
```

5. Add more flows:

```bash
rails generate form_wizard:flow new_flow step1 step2 step3
```

## Documentation

For more information, see the [Form Wizard documentation](https://github.com/your-username/form_wizard).
# Form Wizard Framework

A comprehensive framework for building multi-step forms with configurable steps, validation, and navigation in Ruby on Rails applications.

## Overview

The Form Wizard Framework provides a flexible and powerful way to create multi-step forms (wizards) in your Rails application. It handles the complexities of form state management, validation, navigation between steps, and event handling, allowing you to focus on defining your form's content and business logic.

## Key Features

- **Dynamic Step Registration**: Register form steps with a central registry
- **Flexible Flow Definition**: Define complex navigation paths between steps
- **Validation Framework**: Customizable validation rules for each step
- **Event System**: Subscribe to form lifecycle events
- **Progress Tracking**: Track completion progress across steps
- **Component-Based UI**: ViewComponent integration for form rendering
- **Rails Generators**: Scaffolding for steps, flows, and framework installation

## Installation

Add this to your Gemfile:

```ruby
gem 'form_wizard'
```

Then run:

```bash
bundle install
rails generate form_wizard:install
```

## Core Concepts

### Form Submission

The `FormSubmission` model is the central data store for your form. It:

- Stores form data as JSON
- Tracks completed steps
- Manages the current step
- Calculates progress

```ruby
# Example of creating a form submission
form_submission = FormSubmission.create(session_id: SecureRandom.uuid)
```

### Steps

Steps are the building blocks of your form wizard. Each step:

- Has a unique name
- Contains fields
- Has validation rules
- Can have custom navigation logic

```ruby
# Example of defining a step in a flow
class ContactFormFlow < FormWizard::Flow
  step :personal_info
  step :contact_details
  step :review
end
```

### Flows

Flows define the sequence and navigation logic between steps:

```ruby
class ContactFormFlow < FormWizard::Flow
  flow_name :contact_form
  
  step :personal_info
  step :contact_details
  step :review
  
  # Custom navigation logic
  navigate_to :review, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('first_name').blank?
  }
  
  # Event handlers
  on_complete do |form_submission|
    Rails.logger.info "Form completed: #{form_submission.data.inspect}"
  end
  
  on_step_complete :personal_info do |form_submission|
    Rails.logger.info "Personal info step completed"
  end
end
```

### Services

The framework provides several services to handle form operations:

#### FormSubmissionService

Processes form submissions for a specific step:

```ruby
service = FormWizard::FormSubmissionService.new(form_submission)
result = service.process_step(
  step: 'personal_info',
  params: { 'first_name' => 'John', 'last_name' => 'Doe' },
  flow: ContactFormFlow.new
)

if result.success?
  # Step processed successfully
  next_step = result.next_step
else
  # Handle errors
  errors = result.errors
end
```

#### ValidationService

Validates form data for a specific step:

```ruby
service = FormWizard::ValidationService.new(form_submission)
result = service.validate_step(
  step: 'personal_info',
  params: { 'first_name' => 'John', 'last_name' => 'Doe' },
  flow: ContactFormFlow.new
)

if result.valid?
  # Data is valid
else
  # Handle validation errors
  errors = result.errors
end
```

#### NavigationService

Determines the next step based on the current step and form data:

```ruby
service = FormWizard::NavigationService.new(form_submission)
next_step = service.next_step(
  current_step: 'personal_info',
  flow: ContactFormFlow.new
)
```

### Event System

The framework includes an event system for form lifecycle events:

```ruby
# Subscribe to an event
FormWizard.on(:form_completed) do |form_submission|
  # Do something when a form is completed
end

# Trigger an event
FormWizard.trigger(:form_completed, form_submission)
```

## Building a Form Wizard

### 1. Define Your Flow

Create a new flow class that inherits from `FormWizard::Flow`:

```ruby
# app/flows/contact_form_flow.rb
class ContactFormFlow < FormWizard::Flow
  flow_name :contact_form
  
  step :personal_info
  step :contact_details
  step :review
  
  # Custom navigation logic (optional)
  navigate_to :review, from: :personal_info, if: ->(form_submission) {
    # Skip contact details if no email is needed
    form_submission.get_field_value('needs_contact') == false
  }
  
  # Event handlers (optional)
  on_complete do |form_submission|
    # Send email, save to database, etc.
    NotificationMailer.form_completed(form_submission).deliver_later
  end
end
```

### 2. Create Your Steps

Define your steps with fields and validation rules:

```ruby
# app/steps/personal_info_step.rb
class PersonalInfoStep < FormWizard::Step
  step_name :personal_info
  
  field :first_name, required: true
  field :last_name, required: true
  field :date_of_birth
  
  # Custom validation
  validate do |form_submission, params|
    if params['date_of_birth'].present?
      dob = Date.parse(params['date_of_birth'])
      if dob > 18.years.ago.to_date
        add_error('date_of_birth', 'You must be at least 18 years old')
      end
    end
  end
end
```

### 3. Create Your Controller

```ruby
# app/controllers/form_submissions_controller.rb
class FormSubmissionsController < ApplicationController
  include FormWizard::Controller::FormWizardConcern
  
  def new
    @form_submission = FormSubmission.create(session_id: SecureRandom.uuid)
    redirect_to form_submission_step_path(@form_submission, ContactFormFlow.new.first_step)
  end
  
  def show_step
    @step = params[:step]
    @flow = ContactFormFlow.new
    @form_submission = FormSubmission.find(params[:id])
  end
  
  def process_step
    @step = params[:step]
    @flow = ContactFormFlow.new
    @form_submission = FormSubmission.find(params[:id])
    
    service = FormWizard::FormSubmissionService.new(@form_submission)
    result = service.process_step(
      step: @step,
      params: params[:form_submission],
      flow: @flow
    )
    
    if result.success?
      if result.next_step
        redirect_to form_submission_step_path(@form_submission, result.next_step)
      else
        redirect_to form_submission_complete_path(@form_submission)
      end
    else
      flash[:error] = result.errors.join(', ')
      render :show_step
    end
  end
  
  def complete
    @form_submission = FormSubmission.find(params[:id])
  end
end
```

### 4. Create Your Views

```erb
<!-- app/views/form_submissions/show_step.html.erb -->
<h1>Step: <%= @step %></h1>

<div class="progress">
  <div class="progress-bar" style="width: <%= @form_submission.progress_percentage(@flow) %>%"></div>
</div>

<%= form_with url: process_form_submission_step_path(@form_submission, @step), method: :post do |f| %>
  <% if flash[:error] %>
    <div class="alert alert-danger">
      <%= flash[:error] %>
    </div>
  <% end %>
  
  <% case @step %>
  <% when 'personal_info' %>
    <div class="form-group">
      <%= f.label :first_name %>
      <%= f.text_field :first_name, value: @form_submission.get_field_value('first_name'), class: 'form-control' %>
    </div>
    
    <div class="form-group">
      <%= f.label :last_name %>
      <%= f.text_field :last_name, value: @form_submission.get_field_value('last_name'), class: 'form-control' %>
    </div>
    
    <div class="form-group">
      <%= f.label :date_of_birth %>
      <%= f.date_field :date_of_birth, value: @form_submission.get_field_value('date_of_birth'), class: 'form-control' %>
    </div>
  <% when 'contact_details' %>
    <!-- Contact details fields -->
  <% when 'review' %>
    <!-- Review fields -->
  <% end %>
  
  <div class="form-actions">
    <%= f.submit 'Continue', class: 'btn btn-primary' %>
  </div>
<% end %>
```

## Advanced Usage

### Custom Field Types

You can define custom field types with specific validation rules:

```ruby
class EmailField < FormWizard::Field
  def validate(value)
    unless value =~ /\A[^@\s]+@[^@\s]+\z/
      return "is not a valid email address"
    end
    nil
  end
end

class PhoneNumberField < FormWizard::Field
  def validate(value)
    unless value =~ /\A\+?[\d\s\-\(\)]+\z/
      return "is not a valid phone number"
    end
    nil
  end
end
```

### Conditional Steps

You can make steps conditional based on previous form data:

```ruby
class ApplicationFormFlow < FormWizard::Flow
  step :personal_info
  step :employment_details
  step :education_details
  step :references
  step :review
  
  # Skip employment details for students
  navigate_to :education_details, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('employment_status') == 'student'
  }
  
  # Skip education details for employed people over 30
  navigate_to :references, from: :employment_details, if: ->(form_submission) {
    form_submission.get_field_value('employment_status') == 'employed' &&
    Date.parse(form_submission.get_field_value('date_of_birth')) < 30.years.ago.to_date
  }
end
```

### Form Branching

You can create complex branching logic:

```ruby
class InsuranceApplicationFlow < FormWizard::Flow
  step :personal_info
  step :vehicle_details
  step :home_details
  step :life_details
  step :payment_details
  step :review
  
  # Branch based on insurance type
  navigate_to :vehicle_details, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('insurance_type') == 'vehicle'
  }
  
  navigate_to :home_details, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('insurance_type') == 'home'
  }
  
  navigate_to :life_details, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('insurance_type') == 'life'
  }
  
  # All branches converge at payment details
  navigate_to :payment_details, from: :vehicle_details
  navigate_to :payment_details, from: :home_details
  navigate_to :payment_details, from: :life_details
end
```

## Best Practices

1. **Keep Steps Focused**: Each step should focus on a single aspect of the form
2. **Validate Early**: Validate data as soon as possible to prevent invalid data from progressing
3. **Use Event Handlers**: Leverage event handlers for side effects rather than embedding business logic in controllers
4. **Test Thoroughly**: Write tests for each step's validation and the overall flow navigation
5. **Consider User Experience**: Design your form flow to minimize user frustration and maximize completion rates

## Troubleshooting

### Common Issues

- **Missing Steps**: Ensure all steps are properly registered with the registry
- **Navigation Issues**: Check your navigation rules for conflicts or circular references
- **Validation Errors**: Verify that your validation rules are correctly defined
- **Data Persistence**: Make sure your form submission model is correctly saving data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
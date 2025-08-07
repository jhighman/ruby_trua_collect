# Form Wizard Framework Developer Guide

This guide is designed for developers who may not be fully familiar with Ruby, Metaprogramming, and Inversion of Control patterns. It explains the Form Wizard Framework concepts in a more accessible way.

## Table of Contents

1. [Introduction](#introduction)
2. [Key Concepts for Non-Ruby Developers](#key-concepts-for-non-ruby-developers)
3. [Framework Architecture](#framework-architecture)
4. [Step-by-Step Tutorial](#step-by-step-tutorial)
5. [Advanced Patterns Explained](#advanced-patterns-explained)
6. [Troubleshooting](#troubleshooting)

## Introduction

The Form Wizard Framework is a Ruby on Rails library that helps you build multi-step forms (also called wizards) with features like:

- Breaking complex forms into manageable steps
- Validating each step independently
- Storing form data between steps
- Navigating between steps with custom logic
- Tracking progress through the form

If you've ever used a multi-page checkout process on an e-commerce site, or filled out a job application across multiple pages, you've used something similar to what this framework helps you build.

## Key Concepts for Non-Ruby Developers

### Ruby Language Basics

If you're coming from languages like JavaScript, Java, or C#, here are some Ruby concepts used in this framework:

#### Symbols

Symbols are lightweight strings prefixed with a colon:

```ruby
:personal_info    # This is a symbol
```

They're used extensively as identifiers and are more memory-efficient than strings.

#### Blocks and Lambdas

Ruby uses blocks (chunks of code) that can be passed to methods:

```ruby
# A block using do/end
on_complete do |form_submission|
  # Code that runs when the form is completed
end

# A lambda (anonymous function)
navigate_to :review, from: :personal_info, if: ->(form_submission) {
  form_submission.get_field_value('skip_details') == true
}
```

#### Metaprogramming

Ruby allows code to define or modify itself at runtime:

```ruby
# This is metaprogramming - defining methods dynamically
class FormWizard::Flow
  def self.step(name)
    # This adds a step to the flow when the code is executed
    steps << name
  end
end
```

### Rails Concepts

#### Models

Models represent database tables and business logic:

```ruby
class FormSubmission < ApplicationRecord
  # This model stores form data
end
```

#### Controllers

Controllers handle web requests and responses:

```ruby
class FormSubmissionsController < ApplicationController
  def process_step
    # Handle form submission
  end
end
```

#### Views

Views are templates that generate HTML:

```erb
<!-- app/views/form_submissions/show_step.html.erb -->
<h1>Step: <%= @step %></h1>
```

### Design Patterns

#### Registry Pattern

A central place to store and retrieve objects:

```ruby
# The Step Registry stores all form steps
module FormWizard
  def self.register_step(step)
    registry.register(step)
  end
  
  def self.find_step(name)
    registry.find(name)
  end
end
```

#### Service Objects

Classes that perform specific operations:

```ruby
# ValidationService handles form validation
class FormWizard::ValidationService
  def validate_step(step:, params:, flow:)
    # Validation logic
  end
end
```

#### Domain-Specific Language (DSL)

A specialized syntax for defining specific types of configurations:

```ruby
# This is a DSL for defining form flows
class ContactFormFlow < FormWizard::Flow
  flow_name :contact_form
  
  step :personal_info
  step :contact_details
  step :review
end
```

#### Event System

A publish/subscribe pattern for handling events:

```ruby
# Subscribe to an event
FormWizard.on(:form_completed) do |form_submission|
  # Do something when a form is completed
end

# Trigger an event
FormWizard.trigger(:form_completed, form_submission)
```

## Framework Architecture

The Form Wizard Framework is built with these main components:

### 1. Core Components

- **Registry**: Central storage for steps and flows
- **Step**: Definition of a form step with fields and validation
- **Flow**: Definition of the sequence and navigation between steps
- **Field**: Definition of form fields with validation rules

### 2. Services

- **FormSubmissionService**: Processes form submissions
- **ValidationService**: Validates form data
- **NavigationService**: Determines the next step in a flow

### 3. Model Concerns

- **FormWizardConcern**: Adds form wizard functionality to models

### 4. Controller Concerns

- **FormWizardConcern**: Adds form wizard functionality to controllers

### 5. Event System

- **EventManager**: Manages event subscriptions and triggers

## Step-by-Step Tutorial

Let's build a simple contact form wizard with three steps:

### 1. Create the Form Submission Model

First, we need a model to store our form data:

```ruby
# Generate the model
rails generate model FormSubmission session_id:string data:text current_step:string completed:boolean

# Add form wizard functionality to the model
class FormSubmission < ApplicationRecord
  include FormWizard::Model::FormWizardConcern
  
  # Store form data as JSON
  serialize :data, JSON
  
  # Validations
  validates :session_id, presence: true, uniqueness: true
  
  # Initialize data
  before_validation :initialize_data, on: :create
  
  def initialize_data
    self.data ||= {}
    self.completed ||= false
    self.current_step ||= nil
  end
end
```

### 2. Define Your Steps

Create step classes for each step in your form:

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

# app/steps/contact_details_step.rb
class ContactDetailsStep < FormWizard::Step
  step_name :contact_details
  
  field :email, required: true
  field :phone
  field :preferred_contact, required: true
  
  # Custom validation
  validate do |form_submission, params|
    if params['email'].present? && !params['email'].match?(/\A[^@\s]+@[^@\s]+\z/)
      add_error('email', 'is not a valid email address')
    end
    
    if params['preferred_contact'] == 'phone' && params['phone'].blank?
      add_error('phone', 'is required when preferred contact method is phone')
    end
  end
end

# app/steps/review_step.rb
class ReviewStep < FormWizard::Step
  step_name :review
  
  field :terms_accepted, required: true
  
  # Custom validation
  validate do |form_submission, params|
    unless params['terms_accepted'] == '1'
      add_error('terms_accepted', 'You must confirm the terms to continue')
    end
  end
end
```

### 3. Define Your Flow

Create a flow class that defines the sequence of steps:

```ruby
# app/flows/contact_form_flow.rb
class ContactFormFlow < FormWizard::Flow
  flow_name :contact_form
  
  step :personal_info
  step :contact_details
  step :review
  
  # Skip contact details if no email is provided
  navigate_to :review, from: :personal_info, if: ->(form_submission) {
    form_submission.get_field_value('skip_contact_details') == true
  }
  
  # Event handlers
  on_complete do |form_submission|
    # In a real application, this would send an email or save to a database
    Rails.logger.info "Form completed: #{form_submission.data.inspect}"
  end
  
  on_step_complete :personal_info do |form_submission|
    Rails.logger.info "Personal info step completed"
  end
  
  on_step_complete :contact_details do |form_submission|
    Rails.logger.info "Contact details step completed"
  end
  
  on_step_complete :review do |form_submission|
    Rails.logger.info "Review step completed"
  end
end
```

### 4. Create Your Controller

Create a controller to handle form submissions:

```ruby
# app/controllers/form_submissions_controller.rb
class FormSubmissionsController < ApplicationController
  include FormWizard::Controller::FormWizardConcern
  
  def new
    # Create a new form submission
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
    
    # Process the form submission
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

### 5. Set Up Your Routes

Configure your routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :form_submissions, only: [:new, :create] do
    member do
      get 'step/:step', to: 'form_submissions#show_step', as: :step
      post 'step/:step', to: 'form_submissions#process_step', as: :process_step
      get 'complete', to: 'form_submissions#complete', as: :complete
    end
  end
  
  root to: 'form_submissions#new'
end
```

### 6. Create Your Views

Create views for each step:

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
    
    <div class="form-group">
      <%= f.check_box :skip_contact_details, checked: @form_submission.get_field_value('skip_contact_details') %>
      <%= f.label :skip_contact_details, "Skip contact details" %>
    </div>
  <% when 'contact_details' %>
    <div class="form-group">
      <%= f.label :email %>
      <%= f.email_field :email, value: @form_submission.get_field_value('email'), class: 'form-control' %>
    </div>
    
    <div class="form-group">
      <%= f.label :phone %>
      <%= f.telephone_field :phone, value: @form_submission.get_field_value('phone'), class: 'form-control' %>
    </div>
    
    <div class="form-group">
      <%= f.label :preferred_contact %>
      <%= f.select :preferred_contact, 
                  options_for_select([['Email', 'email'], ['Phone', 'phone']], 
                  @form_submission.get_field_value('preferred_contact')), 
                  {}, class: 'form-control' %>
    </div>
  <% when 'review' %>
    <h2>Personal Information</h2>
    <p><strong>Name:</strong> <%= @form_submission.get_field_value('first_name') %> <%= @form_submission.get_field_value('last_name') %></p>
    <p><strong>Date of Birth:</strong> <%= @form_submission.get_field_value('date_of_birth') %></p>
    
    <h2>Contact Details</h2>
    <p><strong>Email:</strong> <%= @form_submission.get_field_value('email') %></p>
    <p><strong>Phone:</strong> <%= @form_submission.get_field_value('phone') %></p>
    <p><strong>Preferred Contact:</strong> <%= @form_submission.get_field_value('preferred_contact') %></p>
    
    <div class="form-group">
      <%= f.check_box :terms_accepted %>
      <%= f.label :terms_accepted, "I accept the terms and conditions" %>
    </div>
  <% end %>
  
  <div class="form-actions">
    <%= f.submit 'Continue', class: 'btn btn-primary' %>
  </div>
<% end %>
```

Create a completion view:

```erb
<!-- app/views/form_submissions/complete.html.erb -->
<h1>Form Completed</h1>

<div class="alert alert-success">
  Thank you for completing the form!
</div>

<h2>Your Submission</h2>

<h3>Personal Information</h3>
<p><strong>Name:</strong> <%= @form_submission.get_field_value('first_name') %> <%= @form_submission.get_field_value('last_name') %></p>
<p><strong>Date of Birth:</strong> <%= @form_submission.get_field_value('date_of_birth') %></p>

<h3>Contact Details</h3>
<p><strong>Email:</strong> <%= @form_submission.get_field_value('email') %></p>
<p><strong>Phone:</strong> <%= @form_submission.get_field_value('phone') %></p>
<p><strong>Preferred Contact:</strong> <%= @form_submission.get_field_value('preferred_contact') %></p>

<%= link_to 'Start a New Form', new_form_submission_path, class: 'btn btn-primary' %>
```

## Advanced Patterns Explained

### Metaprogramming in the Framework

The framework uses metaprogramming to create a clean, declarative API:

```ruby
# This looks like a simple method call, but it's actually defining
# a step in the form flow
step :personal_info
```

Behind the scenes, this is using Ruby's metaprogramming capabilities:

```ruby
# Simplified version of what happens in the framework
class FormWizard::Flow
  def self.step(name)
    steps << name
    
    # Define a method for this step
    define_method("#{name}_step") do
      # Step-specific logic
    end
  end
end
```

### Inversion of Control

The framework uses Inversion of Control (IoC) to separate concerns:

```ruby
# Instead of directly implementing validation logic in your controller,
# you define it in your step class:
class PersonalInfoStep < FormWizard::Step
  validate do |form_submission, params|
    # Validation logic
  end
end

# Then the framework calls your validation code when needed:
step_instance.validate(form_submission, params)
```

This pattern allows the framework to control when and how your code is executed, while you focus on defining what should happen.

### Event-Driven Architecture

The framework uses events to decouple actions from their consequences:

```ruby
# Define what happens when a form is completed
on_complete do |form_submission|
  # Send email, update database, etc.
end

# Later, when the form is completed, this code is executed
FormWizard.trigger(:form_completed, form_submission)
```

This allows you to add behavior without modifying the core flow logic.

## Troubleshooting

### Common Issues and Solutions

#### "Step not found" error

**Problem**: The framework can't find a step you've defined.

**Solution**: Make sure your step class:
1. Inherits from `FormWizard::Step`
2. Calls `step_name :your_step_name`
3. Is loaded by Rails (should be in app/steps or autoloaded)

#### Validation not working

**Problem**: Your validation rules aren't being applied.

**Solution**:
1. Check that your `validate` block is correctly defined
2. Make sure you're using `add_error` to add validation errors
3. Verify that the params hash contains the expected field names

#### Navigation issues

**Problem**: The form isn't following your navigation rules.

**Solution**:
1. Check that your navigation conditions are correct
2. Make sure the field values you're checking exist in the form submission
3. Verify that you don't have conflicting navigation rules

#### Data not being saved

**Problem**: Form data isn't being saved between steps.

**Solution**:
1. Make sure your FormSubmission model includes the FormWizardConcern
2. Check that your controller is correctly calling the FormSubmissionService
3. Verify that your database is properly configured

### Debugging Tips

1. **Check the logs**: Rails logs will show SQL queries and errors
2. **Use Rails console**: Test your code interactively with `rails console`
3. **Add debug output**: Use `Rails.logger.debug` to log values
4. **Inspect form submissions**: Look at the raw data in the database

```ruby
# In Rails console
submission = FormSubmission.find(123)
puts submission.data.inspect
```

5. **Test services directly**:

```ruby
# In Rails console
submission = FormSubmission.find(123)
service = FormWizard::ValidationService.new(submission)
result = service.validate_step(
  step: 'personal_info',
  params: { 'first_name' => 'John', 'last_name' => 'Doe' },
  flow: ContactFormFlow.new
)
puts result.inspect
```

## Conclusion

The Form Wizard Framework provides a powerful way to build multi-step forms in Rails applications. By understanding the key concepts and patterns used in the framework, you can create complex form flows with minimal code.

Remember that the framework is designed to handle the common challenges of multi-step forms, allowing you to focus on your specific business logic and user experience.

## Related Documentation

- [Data Model](./data_model.md) - Details about the Trua Verify data model
- [Form Wizard Framework](./form_wizard.md) - Documentation for the Form Wizard Framework
- [UI Specification](./UI_spec.md) - Detailed UI specifications for the Form Wizard
- [Future Iterations](./FUTURE_ITERATIONS.md) - Planned enhancements for future development
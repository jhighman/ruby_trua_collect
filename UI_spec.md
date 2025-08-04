# Form Wizard UI Specification

## Overview

The application implements a multi-step form wizard that guides users through a structured data collection process. The wizard is designed to be flexible, with steps that can be conditionally enabled based on configuration requirements. The wizard maintains state throughout the process, validating user input and tracking completion status for each step.

## Current State and Proposed Changes

Currently, the application's root page (`/`) is a task management UI that was implemented as a test of functionality. This should be removed, and the first page of the form wizard should become the entry point of the application.

## Wizard Structure

The wizard consists of the following steps:

1. **Personal Information**
   - Collects basic user information (name, email)
   - Required for all form submissions

2. **Education**
   - Collects education history
   - Includes fields for school, degree, and highest education level
   - Can include multiple education entries

3. **Residence History**
   - Collects residence history
   - Requires continuous coverage for a specified period (typically 3-5 years)
   - Each entry includes address, dates, and current status

4. **Employment History**
   - Collects employment history
   - Each entry includes employer, position, dates, and current status

5. **Professional Licenses**
   - Collects information about professional licenses
   - Each entry includes license type, number, and issuing authority
   - Optional based on configuration

6. **Consents**
   - Collects user consent for various requirements
   - May include driver license consent, drug test consent, biometric consent
   - Required consents are configurable

7. **Signature**
   - Collects user signature and confirmation
   - Finalizes the form submission

## Navigation Flow

1. Users begin at the first enabled step (typically Personal Information)
2. After completing a step, users can proceed to the next step if validation passes
3. Users can navigate back to previous steps to review or modify information
4. The wizard enforces step completion requirements before allowing progression
5. Upon completing all required steps, users are directed to a completion page

## Step Enablement

Steps are conditionally enabled based on the requirements configuration:

- Each step can be individually enabled/disabled
- The wizard automatically redirects to the first enabled step
- Disabled steps are skipped in the navigation flow
- Requirements can be customized per form submission

## Data Model

The wizard's state is maintained in the `FormSubmission` model, which stores:

- Current step ID
- Step values, validation status, and completion status
- User association (if authenticated)
- Session ID (for guest users)
- Requirements configuration

## Validation Rules

Each step has specific validation rules:

1. **Personal Information**
   - Name: Required
   - Email: Required, must be a valid email format

2. **Education**
   - Highest Level: Required, must be one of: high_school, college, masters, doctorate
   - If college or higher is selected, at least one education entry is required

3. **Residence History**
   - At least one entry is required
   - Entries must provide continuous coverage for the required period (3+ years)
   - No gaps allowed in the timeline

4. **Employment History**
   - At least one entry is required
   - Entries should provide continuous coverage where possible

5. **Professional Licenses**
   - Each entry requires license type, number, and issuing authority
   - Optional based on configuration

6. **Consents**
   - Required consents must be accepted
   - Consent requirements are configurable

7. **Signature**
   - Signature: Required
   - Confirmation checkbox: Required

## UI Components

### Step Navigation

- Progress indicator showing completed and current steps
- Next/Previous buttons for step navigation
  - Each step view must include a navigation container with the data attribute `data-form-target="navigation"`
  - Navigation buttons are dynamically rendered by the JavaScript FormController
  - The Previous button is enabled when there is a previous step available
  - Static form submit buttons with name="commit" value="Next" or "Previous" are provided as the primary navigation mechanism
  - These static buttons trigger server-side navigation logic
  - For demonstration purposes, clicking Next always advances to the next step
  - In a production environment, validation would be enforced before advancing
- Step validation occurs on the server side
- Client-side validation is used for immediate feedback

### Form Fields

- Text inputs for simple data entry
- Select dropdowns for enumerated values
- Checkboxes for boolean values
- Dynamic entry forms for timeline data (residence, employment, education)
- Add/Edit/Remove controls for timeline entries

### Timeline Entry Components

For residence, employment, and education history:

- Date range selectors (start date, end date)
- "Current" checkbox for ongoing entries
- Address/employer/school information fields
- Validation for continuous coverage
- Visual timeline representation

### Validation Feedback

- Inline validation messages
- Field-level error indicators
- Step-level validation summary
- Prevents progression if validation fails

## Completion Process

When all required steps are completed:

1. The form is submitted
2. A success page is displayed
3. The user can view their submission details
4. The system may trigger additional processes (e.g., creating a claim)

## Responsive Design

- The wizard is designed to work on both desktop and mobile devices
- Form layouts adapt to screen size
- Touch-friendly controls for mobile users
- Accessible design for all users

## Internationalization

- The wizard supports multiple languages
- Text elements use translation keys
- Date formats adapt to locale
- Language can be switched via the language controller

## Technical Implementation

The wizard is implemented using:

- Rails controllers for server-side logic
- JavaScript for client-side validation and dynamic forms
- JSONB storage for flexible form data
- Service objects for form state management
- Configurable requirements for customization
- Comprehensive test suite for navigation flow

### Testing

The wizard includes automated tests to ensure proper navigation between steps:

- Controller tests verify that submitting a step redirects to the next step
- Tests confirm that the Previous button navigates to the previous step
- Tests validate that step completion status is properly tracked
- End-to-end tests can be run without the UI to verify the navigation flow

A comprehensive test suite has been created in `test_navigation_flow.rb` that tests:

1. Verification that the first step is personal_info
2. Navigation from the personal_info step to the education step
3. Navigation from the education step to the residence_history step
4. Navigation back from the education step to the personal_info step
5. Navigation back from the residence_history step to the education step

These tests have been run and all passed successfully, confirming that the form wizard navigation flow works correctly. The tests verify that:

- The wizard starts with the personal_info step
- The next step after personal_info is education
- The next step after education is residence_history
- The previous step before education is personal_info
- The previous step before residence_history is education

This ensures that the navigation flow is working correctly without needing to run the UI.

## Entry Point Changes

To implement the requested change:

1. Remove the task management UI from the root route
2. Update the routes configuration to make the form wizard the root
3. Ensure the first step of the wizard is properly configured as the entry point
4. Maintain backward compatibility for existing links
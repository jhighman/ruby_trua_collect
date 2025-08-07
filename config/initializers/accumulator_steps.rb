# frozen_string_literal: true

# Configuration for accumulator steps
# This file defines the configuration options for accumulator steps
# Each step can have different validation requirements

Rails.application.config.accumulator_steps = {
  education: {
    entry_name: 'Education',
    entry_name_plural: 'Education Entries',
    required_entries: 1,
    validation_method: :validate_education_entries,
    fields: [
      { name: 'institution', label: 'Institution', required: true },
      { name: 'degree', label: 'Degree', required: false },
      { name: 'field_of_study', label: 'Field of Study', required: false },
      { name: 'location', label: 'Location', required: false },
      { name: 'start_date', label: 'Start Date', required: true },
      { name: 'end_date', label: 'End Date', required: false },
      { name: 'is_current', label: 'Currently Attending', required: false }
    ],
    additional_fields: [
      { name: 'highest_level', label: 'Highest Education Level', required: true }
    ],
    requirements: [
      { name: 'Select your highest education level', check_method: :has_highest_level? },
      { name: 'Add at least one education entry', check_method: :has_entries? },
      { name: 'Ensure all dates are valid', check_method: :has_valid_dates? }
    ]
  },
  residence_history: {
    entry_name: 'Residence',
    entry_name_plural: 'Residences',
    required_entries: 1,
    required_years: 7,
    past_years_only: true,
    validation_method: :validate_residence_entries,
    fields: [
      { name: 'address', label: 'Address', required: true },
      { name: 'city', label: 'City', required: true },
      { name: 'state', label: 'State', required: true },
      { name: 'zip', label: 'ZIP Code', required: true },
      { name: 'start_date', label: 'Start Date', required: true },
      { name: 'end_date', label: 'End Date', required: false },
      { name: 'is_current', label: 'Currently Living Here', required: false }
    ],
    requirements: [
      { name: 'Add at least one residence', check_method: :has_entries? },
      { name: 'Cover the past 7 years of residence history', check_method: :covers_required_years? },
      { name: 'Ensure all dates are valid', check_method: :has_valid_dates? }
    ]
  },
  employment_history: {
    entry_name: 'Employment',
    entry_name_plural: 'Employment History',
    required_entries: 1,
    required_years: 3,
    validation_method: :validate_employment_entries,
    fields: [
      { name: 'employer', label: 'Employer', required: true },
      { name: 'position', label: 'Position', required: true },
      { name: 'location', label: 'Location', required: false },
      { name: 'start_date', label: 'Start Date', required: true },
      { name: 'end_date', label: 'End Date', required: false },
      { name: 'is_current', label: 'Currently Employed Here', required: false }
    ],
    requirements: [
      { name: 'Add at least one employment', check_method: :has_entries? },
      { name: 'Cover at least 3 years of history', check_method: :covers_required_years? },
      { name: 'Ensure all dates are valid', check_method: :has_valid_dates? }
    ]
  }
}
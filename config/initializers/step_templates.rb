# frozen_string_literal: true

# Configuration for step templates
# These templates are used by the DynamicStepService to generate dynamic steps

Rails.application.config.step_templates = {
  # Template for a basic information step
  basic_info: {
    title: 'Basic Information',
    description: 'Please provide some basic information.',
    fields: [
      {
        id: 'first_name',
        label: 'First Name',
        type: 'text',
        required: true
      },
      {
        id: 'last_name',
        label: 'Last Name',
        type: 'text',
        required: true
      },
      {
        id: 'email',
        label: 'Email',
        type: 'email',
        required: true,
        validation: [
          {
            type: 'pattern',
            value: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i,
            message: 'Please enter a valid email address'
          }
        ]
      }
    ]
  },
  
  # Template for an address step
  address: {
    title: 'Address Information',
    description: 'Please provide your address.',
    fields: [
      {
        id: 'street',
        label: 'Street Address',
        type: 'text',
        required: true
      },
      {
        id: 'city',
        label: 'City',
        type: 'text',
        required: true
      },
      {
        id: 'state',
        label: 'State',
        type: 'select',
        options: [
          { value: 'AL', label: 'Alabama' },
          { value: 'AK', label: 'Alaska' },
          # ... other states
          { value: 'WY', label: 'Wyoming' }
        ],
        required: true
      },
      {
        id: 'zip',
        label: 'ZIP Code',
        type: 'text',
        required: true,
        validation: [
          {
            type: 'pattern',
            value: /\A\d{5}(-\d{4})?\z/,
            message: 'Please enter a valid ZIP code'
          }
        ]
      }
    ]
  },
  
  # Template for a document upload step
  document_upload: {
    title: '{{document_type}} Upload',
    description: 'Please upload your {{document_type}}.',
    fields: [
      {
        id: 'document',
        label: '{{document_type}}',
        type: 'file',
        required: true,
        file_validation: {
          max_size: 10, # 10MB
          allowed_types: ['application/pdf', 'image/jpeg', 'image/png'],
          allowed_extensions: ['pdf', 'jpg', 'jpeg', 'png']
        }
      },
      {
        id: 'document_description',
        label: 'Description',
        type: 'textarea',
        required: false
      }
    ]
  },
  
  # Template for a custom question step
  custom_question: {
    title: '{{question_title}}',
    description: '{{question_description}}',
    fields: [
      {
        id: 'answer',
        label: '{{question_label}}',
        type: '{{question_type}}',
        required: true,
        options: '{{question_options}}'
      }
    ]
  },
  
  # Template for a confirmation step
  confirmation: {
    title: 'Confirmation',
    description: 'Please review and confirm your information.',
    fields: [
      {
        id: 'confirm',
        label: 'I confirm that all information provided is accurate and complete.',
        type: 'checkbox',
        required: true
      }
    ]
  }
}

# Configuration for workflow templates
# These templates are used by the MultiPathWorkflowService to generate workflows

Rails.application.config.workflow_templates = {
  # Template for a basic verification workflow
  basic_verification: {
    default_path: 'standard',
    paths: {
      # Standard path for most users
      standard: {
        name: 'Standard Verification',
        description: 'Standard verification process for most users.',
        steps: [
          'personal_info',
          'residence_history',
          'employment_history',
          'education',
          'signature'
        ]
      },
      
      # Enhanced path for users requiring additional verification
      enhanced: {
        name: 'Enhanced Verification',
        description: 'Enhanced verification process with additional steps.',
        steps: [
          'personal_info',
          'residence_history',
          'employment_history',
          'education',
          'document_upload_id',
          'document_upload_proof_of_address',
          'signature'
        ],
        conditions: {
          type: 'or',
          conditions: [
            {
              type: 'equals',
              field: 'personal_info.risk_level',
              value: 'high'
            },
            {
              type: 'equals',
              field: 'personal_info.country',
              value: 'International'
            }
          ]
        }
      },
      
      # Simplified path for low-risk users
      simplified: {
        name: 'Simplified Verification',
        description: 'Simplified verification process for low-risk users.',
        steps: [
          'personal_info',
          'residence_history',
          'signature'
        ],
        conditions: {
          type: 'and',
          conditions: [
            {
              type: 'equals',
              field: 'personal_info.risk_level',
              value: 'low'
            },
            {
              type: 'equals',
              field: 'personal_info.country',
              value: 'US'
            }
          ]
        }
      }
    },
    
    # Decision points in the workflow
    decision_points: {
      'personal_info': {
        'standard': {
          label: 'Continue with standard verification',
          path: 'standard',
          next_step: 'residence_history'
        },
        'enhanced': {
          label: 'Continue with enhanced verification',
          path: 'enhanced',
          next_step: 'residence_history'
        },
        'simplified': {
          label: 'Continue with simplified verification',
          path: 'simplified',
          next_step: 'residence_history'
        }
      }
    }
  }
}
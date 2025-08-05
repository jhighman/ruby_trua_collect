// Form Wizard JavaScript

document.addEventListener('DOMContentLoaded', function() {
  initFormWizard();
});

function initFormWizard() {
  // Initialize client-side validation
  initValidation();
  
  // Initialize conditional fields
  initConditionalFields();
  
  // Initialize form submission handling
  initFormSubmission();
}

function initValidation() {
  const form = document.querySelector('.form-wizard-form');
  if (!form) return;
  
  // Add validation to required fields
  const requiredFields = form.querySelectorAll('[required]');
  requiredFields.forEach(field => {
    field.addEventListener('blur', function() {
      validateField(field);
    });
  });
  
  // Add validation to the form submission
  form.addEventListener('submit', function(event) {
    let isValid = true;
    
    requiredFields.forEach(field => {
      if (!validateField(field)) {
        isValid = false;
      }
    });
    
    if (!isValid) {
      event.preventDefault();
    }
  });
}

function validateField(field) {
  const fieldContainer = field.closest('.form-group');
  const errorElement = fieldContainer.querySelector('.field-error') || createErrorElement(fieldContainer);
  
  // Clear previous errors
  errorElement.textContent = '';
  
  // Check if the field is empty
  if (field.hasAttribute('required') && !field.value.trim()) {
    errorElement.textContent = 'This field is required';
    return false;
  }
  
  // Check for pattern validation
  if (field.hasAttribute('pattern') && field.value) {
    const pattern = new RegExp(field.getAttribute('pattern'));
    if (!pattern.test(field.value)) {
      errorElement.textContent = field.getAttribute('data-pattern-message') || 'Invalid format';
      return false;
    }
  }
  
  // Check for min/max validation
  if (field.type === 'number') {
    const value = parseFloat(field.value);
    const min = parseFloat(field.getAttribute('min'));
    const max = parseFloat(field.getAttribute('max'));
    
    if (!isNaN(min) && value < min) {
      errorElement.textContent = `Value must be at least ${min}`;
      return false;
    }
    
    if (!isNaN(max) && value > max) {
      errorElement.textContent = `Value must be at most ${max}`;
      return false;
    }
  }
  
  return true;
}

function createErrorElement(fieldContainer) {
  const errorElement = document.createElement('div');
  errorElement.className = 'field-error';
  fieldContainer.appendChild(errorElement);
  return errorElement;
}

function initConditionalFields() {
  const form = document.querySelector('.form-wizard-form');
  if (!form) return;
  
  // Find all fields with data-depends-on attribute
  const conditionalFields = form.querySelectorAll('[data-depends-on]');
  
  conditionalFields.forEach(field => {
    const fieldContainer = field.closest('.form-group');
    const dependsOn = field.getAttribute('data-depends-on');
    const dependsOnValue = field.getAttribute('data-depends-on-value');
    const dependsOnField = form.querySelector(`[name="${dependsOn}"]`);
    
    if (dependsOnField) {
      // Initial check
      updateConditionalField(dependsOnField, fieldContainer, dependsOnValue);
      
      // Add change listener
      dependsOnField.addEventListener('change', function() {
        updateConditionalField(dependsOnField, fieldContainer, dependsOnValue);
      });
    }
  });
}

function updateConditionalField(dependsOnField, fieldContainer, dependsOnValue) {
  let shouldShow = false;
  
  if (dependsOnField.type === 'checkbox') {
    shouldShow = dependsOnField.checked === (dependsOnValue === 'true');
  } else if (dependsOnField.type === 'radio') {
    const radioGroup = document.querySelectorAll(`[name="${dependsOnField.name}"]:checked`);
    if (radioGroup.length) {
      shouldShow = radioGroup[0].value === dependsOnValue;
    }
  } else {
    shouldShow = dependsOnField.value === dependsOnValue;
  }
  
  fieldContainer.style.display = shouldShow ? 'block' : 'none';
  
  // Disable fields when hidden to prevent them from being submitted
  const fields = fieldContainer.querySelectorAll('input, select, textarea');
  fields.forEach(field => {
    field.disabled = !shouldShow;
  });
}

function initFormSubmission() {
  const form = document.querySelector('.form-wizard-form');
  if (!form) return;
  
  // Add AJAX validation before form submission
  form.addEventListener('submit', function(event) {
    const submitButton = form.querySelector('input[type="submit"]');
    if (submitButton) {
      submitButton.disabled = true;
      submitButton.value = 'Processing...';
    }
  });
}

// Helper function to validate a step via AJAX
function validateStepAjax(formData, callback) {
  const xhr = new XMLHttpRequest();
  xhr.open('POST', '/form/validate_step', true);
  xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.setRequestHeader('X-CSRF-Token', document.querySelector('meta[name="csrf-token"]').content);
  
  xhr.onload = function() {
    if (xhr.status === 200) {
      const response = JSON.parse(xhr.responseText);
      callback(response);
    } else {
      callback({ valid: false, errors: ['An error occurred during validation'] });
    }
  };
  
  xhr.onerror = function() {
    callback({ valid: false, errors: ['An error occurred during validation'] });
  };
  
  xhr.send(JSON.stringify(formData));
}

// Helper function to show errors
function showErrors(errors) {
  const errorContainer = document.querySelector('.form-wizard-errors');
  if (!errorContainer) return;
  
  const errorList = document.createElement('ul');
  
  errors.forEach(error => {
    const errorItem = document.createElement('li');
    errorItem.textContent = error;
    errorList.appendChild(errorItem);
  });
  
  errorContainer.innerHTML = '';
  errorContainer.appendChild(errorList);
  errorContainer.style.display = 'block';
  
  // Scroll to errors
  errorContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// This file uses regular JavaScript instead of ES modules for better compatibility

// Add error handling for module loading failures
document.addEventListener('DOMContentLoaded', function() {
  // Check if Turbo is available, if not load it manually
  if (typeof window.Turbo === 'undefined') {
    var turboScript = document.createElement('script');
    turboScript.src = '/assets/turbo.min.js';
    document.head.appendChild(turboScript);
  }
  
  // Listen for module loading errors
  window.addEventListener('error', function(event) {
    if (event.message && event.message.includes('Failed to load module')) {
      console.warn('Module loading error detected:', event.message);
      console.info('Using fallback UI components instead');
    }
  });
  
  // Initialize UI components if needed
  if (typeof window.UI === 'undefined') {
    console.warn('UI components not loaded, initializing fallbacks');
    window.UI = window.UI || {
      Button: {
        render: function(props) {
          var btn = document.createElement('button');
          btn.className = 'btn btn-primary';
          btn.textContent = props?.text || '';
          return btn;
        }
      },
      Form: {
        render: function(props) {
          var form = document.createElement('form');
          form.className = props?.className || '';
          return form;
        }
      }
    };
  }
});

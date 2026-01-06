// Fallback implementations for UI components
// This file provides non-module implementations of the UI components
// to ensure basic functionality when ES modules fail to load

// Utility functions
function cn() {
  return Array.prototype.slice.call(arguments).filter(Boolean).join(' ');
}

// Button component fallback
var Button = {
  render: function(props) {
    props = props || {};
    var className = props.className;
    var variant = props.variant || 'default';
    var size = props.size || 'default';
    var children = props.children || '';
    var onClick = props.onClick;
    
    var baseClasses = 'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none';
    var variantClasses = {
      default: 'bg-primary text-primary-foreground hover:bg-primary/90',
      destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
      outline: 'border border-input hover:bg-accent hover:text-accent-foreground',
      secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
      ghost: 'hover:bg-accent hover:text-accent-foreground',
      link: 'underline-offset-4 hover:underline text-primary',
    };
    var sizeClasses = {
      default: 'h-10 py-2 px-4',
      sm: 'h-9 px-3 rounded-md',
      lg: 'h-11 px-8 rounded-md',
      icon: 'h-10 w-10',
    };
    
    var classes = [
      baseClasses,
      variantClasses[variant],
      sizeClasses[size],
      className
    ].filter(Boolean).join(' ');
    
    var button = document.createElement('button');
    button.className = classes;
    button.innerHTML = children;
    if (onClick) {
      button.addEventListener('click', onClick);
    }
    
    return button;
  }
};

// Form component fallback
var Form = {
  render: function(props) {
    props = props || {};
    var className = props.className || '';
    var children = props.children || '';
    var onSubmit = props.onSubmit;
    
    var form = document.createElement('form');
    form.className = className;
    form.innerHTML = children;
    if (onSubmit) {
      form.addEventListener('submit', onSubmit);
    }
    
    return form;
  }
};

// FileUpload component fallback
var FileUpload = {
  render: function(props) {
    props = props || {};
    var className = props.className || '';
    var onChange = props.onChange;
    
    var container = document.createElement('div');
    container.className = className;
    
    var input = document.createElement('input');
    input.type = 'file';
    input.className = 'hidden';
    
    var label = document.createElement('label');
    label.className = 'cursor-pointer inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none border border-input hover:bg-accent hover:text-accent-foreground h-10 py-2 px-4';
    label.textContent = 'Upload file';
    
    if (onChange) {
      input.addEventListener('change', onChange);
    }
    
    container.appendChild(input);
    container.appendChild(label);
    
    return container;
  }
};

// Timeline component fallback
var Timeline = {
  render: function(props) {
    props = props || {};
    var className = props.className || '';
    var items = props.items || [];
    
    var container = document.createElement('div');
    container.className = className;
    
    if (items && Array.isArray(items)) {
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        var index = i;
        
        var entry = document.createElement('div');
        entry.className = 'timeline-entry mb-4 border-l-2 border-gray-200 pl-4';
        
        var title = document.createElement('h3');
        title.className = 'font-medium';
        title.textContent = item.title || 'Entry ' + (index + 1);
        
        var content = document.createElement('div');
        content.className = 'text-sm text-gray-600';
        content.textContent = item.content || '';
        
        entry.appendChild(title);
        entry.appendChild(content);
        container.appendChild(entry);
      }
    }
    
    return container;
  }
};

// Make fallbacks available globally
window.UI = {
  cn: cn,
  Button: Button,
  Form: Form,
  FileUpload: FileUpload,
  Timeline: Timeline
};
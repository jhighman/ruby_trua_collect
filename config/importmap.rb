# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", preload: true
pin "@hotwired/stimulus", preload: true
pin "@hotwired/stimulus-loading", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/components", under: "components"

# Add fallbacks
pin "fallbacks", to: "fallbacks.js", preload: true

# Explicitly pin UI components with correct MIME type
pin "components/ui/button", to: "components/ui/button.js", preload: true
pin "components/ui/file-upload", to: "components/ui/file-upload.js", preload: true
pin "components/ui/form", to: "components/ui/form.js", preload: true
pin "components/ui/timeline", to: "components/ui/timeline.js", preload: true

# Pin React and other dependencies
pin "react", to: "https://ga.jspm.io/npm:react@18.2.0/index.js"
pin "react-dom", to: "https://ga.jspm.io/npm:react-dom@18.2.0/index.js"
pin "scheduler", to: "https://ga.jspm.io/npm:scheduler@0.23.0/index.js"
pin "class-variance-authority", to: "https://cdn.jsdelivr.net/npm/class-variance-authority@0.7.0/dist/index.min.js"
pin "clsx", to: "https://cdn.jsdelivr.net/npm/clsx@2.0.0/dist/clsx.min.js"
pin "tailwind-merge", to: "https://cdn.jsdelivr.net/npm/tailwind-merge@3.4.0/+esm"

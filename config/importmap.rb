# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/components", under: "components"

# Explicitly pin UI components
pin "components/ui/button", to: "components/ui/button.js"
pin "components/ui/file-upload", to: "components/ui/file-upload.js"
pin "components/ui/form", to: "components/ui/form.js"
pin "components/ui/timeline", to: "components/ui/timeline.js"

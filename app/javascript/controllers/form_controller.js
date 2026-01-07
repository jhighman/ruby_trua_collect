import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "errorContainer", "navigation", "timelineEntries"]
  static values = {
    stepId: String,
    formId: String,
    requirements: Object,
    formState: Object,
    navigationState: Object
  }

  connect() {
    console.log("Form controller connected successfully!", {
      stepId: this.stepIdValue,
      formId: this.formIdValue,
      element: this.element,
      fieldTargets: this.fieldTargets.length,
      hasNavigationTarget: this.hasNavigationTarget
    })
    
    this.validateOnInput()
    this.fetchFormState()
    
    // Initialize toggle states
    this.initializeToggles()
  }
  
  initializeToggles() {
    console.log("Initializing toggles — using data-action attributes")
    
    // Initial state for current employer
    const isCurrentCheckbox = this.element.querySelector('input[name="entry[is_current]"]')
    if (isCurrentCheckbox && isCurrentCheckbox.checked) {
      this.toggleEndDate({ target: isCurrentCheckbox })
    }
    
    // Initial state for no contact
    const noContactCheckbox = this.element.querySelector('input[name="entry[no_contact]"]')
    if (noContactCheckbox && noContactCheckbox.checked) {
      this.toggleContactFields({ target: noContactCheckbox })
    }
  }

  validateOnInput() {
    this.fieldTargets.forEach(field => {
      field.addEventListener("input", () => this.validateField(field))
      field.addEventListener("change", () => this.validateField(field))
    })
  }
  
  async fetchFormState() {
    console.log("fetchFormState called", { formId: this.formIdValue })
    
    try {
      const response = await fetch(`/form_submissions_api/${this.formIdValue}/state`)
      console.log("Form state API response:", response)
      
      if (!response.ok) {
        console.error("Error fetching form state:", response.status, response.statusText)
        return
      }
      
      const data = await response.json()
      console.log("Form state data:", data)
      
      this.formStateValue = data.form_state
      this.navigationStateValue = data.navigation_state
      this.requirementsValue = data.requirements
      
      console.log("Updated form state values:", {
        formState: this.formStateValue,
        navigationState: this.navigationStateValue,
        requirements: this.requirementsValue
      })
      
      this.updateNavigation()
      
      if (this.hasTimelineEntriesTarget) {
        this.updateTimelineEntries()
      }
    } catch (error) {
      console.error("Error in fetchFormState:", error)
    }
  }

  validateField(field) {
    // Skip validation for non-required fields that are empty
    if (!field.required && !field.value) return true

    let isValid = field.checkValidity()
    
    if (isValid) {
      field.classList.remove("is-invalid")
      field.classList.add("is-valid")
    } else {
      field.classList.remove("is-valid")
      field.classList.add("is-invalid")
    }
    
    return isValid
  }

  validateStep() {
    let isValid = true
    
    this.fieldTargets.forEach(field => {
      if (!this.validateField(field)) {
        isValid = false
      }
    })
    
    return isValid
  }

  validateStepOnServer(event) {
    console.log("validateStepOnServer called", { event, stepId: this.stepIdValue })
    
    // Prevent form submission if client-side validation fails
    if (!this.validateStep()) {
      console.log("Client-side validation failed, preventing form submission")
      event.preventDefault()
      return
    }
    
    // Get form data
    const formData = new FormData(this.element)
    console.log("Form data:", Object.fromEntries(formData))
    
    // Add step_id to form data
    formData.append("step_id", this.stepIdValue)
    
    // Send validation request to server
    console.log("Sending validation request to server")
    
    // Use the form's action URL instead of a hardcoded API endpoint
    const formAction = this.element.action
    console.log("Form action URL:", formAction)
    
    // Submit the form directly instead of using fetch
    // This will let Rails handle the form submission properly
    return true
  }
  
  async moveToNextStep() {
    console.log("moveToNextStep called", {
      stepId: this.stepIdValue,
      navigationState: this.navigationStateValue
    })
    
    const currentIndex = this.navigationStateValue.available_steps.indexOf(this.stepIdValue)
    console.log("Current index:", currentIndex)
    
    if (currentIndex === this.navigationStateValue.available_steps.length - 1) {
      console.log("Last step, submitting form")
      this.submitForm()
    } else if (this.navigationStateValue.can_move_next) {
      const nextStep = this.navigationStateValue.available_steps[currentIndex + 1]
      console.log("Moving to next step:", nextStep)
      await this.moveToStep(nextStep)
    } else {
      console.log("Cannot move to next step")
    }
  }

  async moveToPreviousStep() {
    const currentIndex = this.navigationStateValue.available_steps.indexOf(this.stepIdValue)
    if (currentIndex > 0 && this.navigationStateValue.can_move_previous) {
      const prevStep = this.navigationStateValue.available_steps[currentIndex - 1]
      await this.moveToStep(prevStep)
    }
  }

  async moveToStep(stepId) {
    await fetch(`/form_submissions_api/${this.formIdValue}/move_to_step`, {
      method: "POST",
      body: JSON.stringify({ step_id: stepId }),
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
    
    window.location.href = `/form?step_id=${stepId}`
  }
  
  async submitForm() {
    const response = await fetch(`/form_submissions_api/submit`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ id: this.formIdValue })
    })
    
    const data = await response.json()
    
    if (data.success) {
      window.location.href = "/form/complete"
    } else {
      this.showErrors(data.errors)
    }
  }
  
  async addTimelineEntry(event) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const response = await fetch(`/form_submissions_api/${this.formIdValue}/add_timeline_entry?step_id=${this.stepIdValue}`, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
    
    const data = await response.json()
    this.updateTimelineEntries(data.entries)
  }

  async updateTimelineEntry(event, index) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const response = await fetch(`/form_submissions_api/${this.formIdValue}/update_timeline_entry?step_id=${this.stepIdValue}&index=${index}`, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
    
    const data = await response.json()
    this.updateTimelineEntries(data.entries)
  }

  async removeTimelineEntry(event) {
    event.preventDefault()
    const index = event.currentTarget.dataset.index
    
    const response = await fetch(`/form_submissions_api/${this.formIdValue}/remove_timeline_entry?step_id=${this.stepIdValue}&index=${index}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
    
    const data = await response.json()
    this.updateTimelineEntries(data.entries)
  }
  
  updateTimelineEntries(entries) {
    if (!this.hasTimelineEntriesTarget) return
    
    const entriesData = entries || this.formStateValue?.steps?.[this.stepIdValue]?.values?.entries || []
    
    let html = ''
    entriesData.forEach((entry, index) => {
      html += `
        <div class="timeline-entry mb-3 border rounded p-4 bg-white">
          <div class="flex justify-between">
            <h5 class="font-medium">${entry.company || ''} - ${entry.position || ''}</h5>
            <a href="/form/${this.formIdValue}?step_id=${this.stepIdValue}&entry_index=${index}"
               data-method="delete"
               data-confirm="Are you sure you want to remove this employment entry?"
               class="text-red-600 hover:text-red-800">Remove</a>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-2">
            <div>
              <p class="text-sm text-muted-foreground">Start Date</p>
              <p>${entry.start_date || ''}</p>
            </div>
            <div>
              <p class="text-sm text-muted-foreground">End Date</p>
              <p>${entry.is_current ? 'Current' : (entry.end_date || '')}</p>
            </div>
          </div>
          <div class="mt-2">
            <p class="text-sm text-muted-foreground">Location</p>
            <p>${entry.city || ''}, ${entry.state_province || ''}, ${entry.country || ''}</p>
          </div>
          ${entry.description ? `
            <div class="mt-2">
              <p class="text-sm text-muted-foreground">Description</p>
              <p>${entry.description}</p>
            </div>
          ` : ''}
          ${entry.contact_name || entry.contact_email || entry.contact_phone ? `
            <div class="mt-2 pt-2 border-t">
              <p class="text-sm text-muted-foreground font-medium">Contact Information</p>
              ${entry.contact_name ? `<p class="mb-1"><span class="font-medium">Name:</span> ${entry.contact_name}</p>` : ''}
              ${entry.contact_email ? `<p class="mb-1"><span class="font-medium">Email:</span> ${entry.contact_email}</p>` : ''}
              ${entry.contact_phone ? `<p class="mb-1"><span class="font-medium">Phone:</span> ${entry.contact_phone}</p>` : ''}
            </div>
          ` : entry.no_contact ? `
            <div class="mt-2 pt-2 border-t">
              <p class="text-sm text-muted-foreground font-medium">Contact Information</p>
              <p class="italic text-gray-500">No contact information available</p>
            </div>
          ` : ''}
        </div>
      `
    })
    
    this.timelineEntriesTarget.innerHTML = html
  }
  
  updateNavigation() {
    console.log("updateNavigation called", {
      hasNavigationTarget: this.hasNavigationTarget,
      navigationState: this.navigationStateValue
    })
    
    if (!this.hasNavigationTarget) {
      console.log("No navigation target found")
      return
    }
    
    let html = ''
    
    if (this.navigationStateValue?.can_move_previous) {
      console.log("Adding Previous button")
      html += `<button type="button" class="btn btn-outline-secondary" data-action="click->form#moveToPreviousStep">Previous</button>`
    }
    
    if (this.navigationStateValue?.can_move_next) {
      console.log("Adding Next button")
      html += `<button type="button" class="btn btn-primary ms-2" data-action="click->form#moveToNextStep">Next</button>`
    } else {
      console.log("Not adding Next button because can_move_next is false")
    }
    
    console.log("Setting navigation HTML:", html)
    this.navigationTarget.innerHTML = html
  }

  showErrors(errors) {
    if (!this.hasErrorContainerTarget) return
    
    // Clear existing errors
    this.errorContainerTarget.innerHTML = ""
    
    // Add new errors
    if (Object.keys(errors).length > 0) {
      const errorList = document.createElement("ul")
      errorList.classList.add("mb-0")
      
      Object.entries(errors).forEach(([field, error]) => {
        const errorItem = document.createElement("li")
        errorItem.textContent = `${field.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}: ${error}`
        errorList.appendChild(errorItem)
        
        // Highlight the field with error
        const fieldElement = this.fieldTargets.find(f => f.name === field || f.name.endsWith(`[${field}]`))
        if (fieldElement) {
          fieldElement.classList.remove("is-valid")
          fieldElement.classList.add("is-invalid")
        }
      })
      
      this.errorContainerTarget.appendChild(errorList)
    }
  }

  toggleEducationEntries(event) {
    const selectedValue = event.target.value
    const entriesContainer = document.getElementById("education-entries")
    
    if (entriesContainer) {
      if (["college", "masters", "doctorate"].includes(selectedValue)) {
        entriesContainer.classList.remove("d-none")
      } else {
        entriesContainer.classList.add("d-none")
      }
    }
  }

  toggleEndDate(event) {
    console.log("🔥🔥 TOGGLED CURRENT EMPLOYER!", {
      checked: event.target.checked,
      checkbox: event.target,
      container: document.getElementById("end-date-container")
    })

    const checkbox = event.target
    const container = document.getElementById("end-date-container")
    
    if (!container) {
      console.error("❌ END DATE CONTAINER NOT FOUND")
      return
    }

    const field = container.querySelector("input")
    
    if (checkbox.checked) {
      console.log("Hiding end date")
      if (!container.dataset.originalDisplay) {
        container.dataset.originalDisplay = window.getComputedStyle(container).display
      }
      container.style.display = "none"
      
      if (field) {
        field.disabled = true
        field.required = false
        field.value = ""
        console.log("End date field disabled and cleared")
      }
    } else {
      console.log("Showing end date")
      const original = container.dataset.originalDisplay || "block"
      container.style.display = original
      
      if (field) {
        field.disabled = false
        field.required = true
        console.log("End date field enabled")
      }
    }
  }
  
  toggleContactFields(event) {
    console.log("🔥🔥 TOGGLED NO CONTACT!", {
      checked: event.target.checked,
      checkbox: event.target,
      container: document.getElementById("contact-fields-container")
    })
    
    const checkbox = event.target
    const container = document.getElementById("contact-fields-container")
    
    if (!container) {
      console.error("❌ CONTACT FIELDS CONTAINER NOT FOUND")
      return
    }
    
    // Save original display only once
    if (!container.dataset.originalDisplay) {
      container.dataset.originalDisplay = window.getComputedStyle(container).display
      console.log("Saved original display:", container.dataset.originalDisplay)
    }
    
    if (checkbox.checked) {
      console.log("Hiding contact fields")
      container.style.display = "none"
      
      // Disable required validation for contact fields
      const contactFields = container.querySelectorAll("input")
      contactFields.forEach(field => {
        field.disabled = true
        field.required = false
        console.log("Disabled field:", field.name)
      })
    } else {
      console.log("Showing contact fields")
      const original = container.dataset.originalDisplay || "grid"
      container.style.display = original
      
      // Re-enable fields but don't make them required individually
      // We'll validate that at least one is filled in the server-side validation
      const contactFields = container.querySelectorAll("input")
      contactFields.forEach(field => {
        field.disabled = false
        console.log("Enabled field:", field.name)
      })
    }
  }
}
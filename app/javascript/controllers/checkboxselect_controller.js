import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkboxAll", "checkbox", "errorMessage"]
  static values = { errorText: String }

  connect() {
    this.resetCheckboxes()
  }

  resetCheckboxes() {
    this.checkboxTargets.forEach(checkbox => checkbox.checked = false)
    this.checkboxAllTarget.checked = false
  }

  toggleCheckbox() {
    const isChecked = this.checkboxAllTarget.checked
    this.checkboxTargets.forEach(checkbox => checkbox.checked = isChecked)
  }

  toggleCheckboxAll() {
    this.checkboxAllTarget.checked = this.checkboxTargets.every(checkbox => checkbox.checked)
  }

  submitForm(event) {
    if (!this.checkboxTargets.some(checkbox => checkbox.checked)) {
      event.preventDefault()
      this.setErrorMessage(this.errorTextValue || "Please select at least one description.")
    } else {
      this.clearErrorMessage()
    }
  }

  clearErrorMessage() {
    this.errorMessageTarget.innerHTML = ''
  }

  setErrorMessage(message) {
    this.errorMessageTarget.innerHTML = message
  }
}
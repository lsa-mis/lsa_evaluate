import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["activeCheckbox", "submitButton"]
  static values = {
    isNewRecord: Boolean,
    confirmMessage: String
  }

  connect() {
    console.log("contest-activation controller connected")
    console.log("isNewRecord:", this.isNewRecordValue)
    console.log("hasSubmitButtonTarget:", this.hasSubmitButtonTarget)
    if (this.isNewRecordValue && this.hasSubmitButtonTarget) {
      this.submitButtonTarget.addEventListener('click', this.handleButtonClick.bind(this))
      console.log("Event listener added to submit button")
    }
  }

  handleButtonClick(event) {
    console.log("=== handleButtonClick called ===")
    console.log("isNewRecord:", this.isNewRecordValue)
    console.log("checkbox checked:", this.activeCheckboxTarget.checked)

    // Only prompt for new records (creation)
    if (!this.isNewRecordValue) {
      console.log("Not a new record, returning")
      return
    }

    // If active checkbox is already checked, proceed normally
    if (this.activeCheckboxTarget.checked) {
      console.log("Checkbox already checked, proceeding normally")
      return
    }

    // Show confirmation dialog synchronously
    const message = this.confirmMessageValue ||
      "This contest will be created as inactive. Would you like to make it active now? " +
      "Active contests allow administrators to manage entries and judges to provide feedback during their assigned periods."

    const userConfirmed = confirm(message)
    console.log("User confirmed:", userConfirmed)

    if (userConfirmed) {
      // User wants to activate - check the checkbox
      this.activeCheckboxTarget.checked = true
      console.log("Checkbox set to checked")
    } else {
      console.log("User cancelled, checkbox remains unchecked")
    }

    // Let the normal form submission proceed
    console.log("Allowing normal form submission to proceed")
  }

  checkActivation(event) {
    // This method is no longer used
  }
}

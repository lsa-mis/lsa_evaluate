import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateOpen", "dateClosed", "form"]

  connect() {
    this.validateDates()
    console.log("form validation controller connected")
  }

  validateDates() {
    const dateOpen = new Date(this.dateOpenTarget.value)
    const dateClosed = new Date(this.dateClosedTarget.value)

    if (dateClosed <= dateOpen) {
      this.dateClosedTarget.setCustomValidity("Whoops, Close date must be after open date")
    } else {
      this.dateClosedTarget.setCustomValidity("")
    }
  }

  submitForm(event) {
    this.validateDates()
    if (!this.formTarget.checkValidity()) {
      event.preventDefault()
      this.formTarget.reportValidity()
    }
  }
}
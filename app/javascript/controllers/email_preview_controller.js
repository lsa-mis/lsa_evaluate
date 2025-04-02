import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["baseEmail", "optionsEmail"]
  static values = { type: { type: String, default: "base" } }

  connect() {
    console.log("Email preview controller connected")

    // Add event listener for the Bootstrap modal shown event
    const modal = this.element.closest('.modal')
    if (modal) {
      console.log("Modal found, adding event listener")
      modal.addEventListener('shown.bs.modal', () => {
        console.log("Modal shown event triggered")
        console.log("Current type value:", this.typeValue)
        this.updatePreview()
      })
    }
  }

  // Set the type value when a button is clicked
  setType(event) {
    const newType = event.currentTarget.dataset.previewType
    console.log("Setting type to:", newType)
    this.typeValue = newType
  }

  // Update the preview based on the current type
  updatePreview() {
    console.log("Updating preview with type:", this.typeValue)

    if (this.typeValue === "base") {
      this.showBaseEmail()
    } else if (this.typeValue === "options") {
      this.showOptionsEmail()
    }
  }

  showBaseEmail() {
    console.log("Showing base email")
    this.baseEmailTarget.style.display = "block"
    this.optionsEmailTarget.style.display = "none"
  }

  showOptionsEmail() {
    console.log("Showing options email")
    this.baseEmailTarget.style.display = "none"
    this.optionsEmailTarget.style.display = "block"
  }
}

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="character-counter"
export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { maximum: Number }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const charCount = this.input.value.length
    const maximumChars = this.maximumValue

    this.counterTarget.textContent = `${charCount}`

    if (maximumChars > 0) {
      if (charCount <= maximumChars) {
        this.counterTarget.classList.remove('text-danger')
        this.counterTarget.classList.add('text-success')
      } else {
        this.counterTarget.classList.remove('text-success')
        this.counterTarget.classList.add('text-danger')
      }
    }
  }

  get input() {
    return this.inputTarget
  }
}

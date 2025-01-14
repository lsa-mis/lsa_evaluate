import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "counter"]
  static values = {
    minimum: Number
  }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const words = this.countWords(this.textareaTarget.value)
    this.counterTarget.textContent = words

    if (this.hasMinimumValue && this.minimumValue > 0) {
      if (words >= this.minimumValue) {
        this.counterTarget.classList.remove('text-danger')
        this.counterTarget.classList.add('text-success')
        this.textareaTarget.classList.remove('is-invalid')
        this.textareaTarget.classList.add('is-valid')
      } else {
        this.counterTarget.classList.remove('text-success')
        this.counterTarget.classList.add('text-danger')
        this.textareaTarget.classList.remove('is-valid')
        this.textareaTarget.classList.add('is-invalid')
      }
    }
  }

  countWords(str) {
    return str.trim().split(/\s+/).filter(word => word.length > 0).length
  }
}

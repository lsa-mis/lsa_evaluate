import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { minimum: Number }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const wordCount = this.input.value.trim().split(/\s+/).filter(Boolean).length
    const minimumWords = this.minimumValue

    this.counterTarget.textContent = `${wordCount}/${minimumWords} words`

    if (minimumWords > 0) {
      if (wordCount >= minimumWords) {
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

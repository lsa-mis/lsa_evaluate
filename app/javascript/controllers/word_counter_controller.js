import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]

  connect() {
    this.count()
  }

  count() {
    this.inputTargets.forEach(input => {
      const minWords = parseInt(input.dataset.minWords) || 0
      const isRequired = input.dataset.required === "true"
      const counter = input.nextElementSibling
      if (!counter || !counter.matches('[data-word-counter-target="counter"]')) return

      const words = this.countWords(input.value)
      counter.textContent = `Words: ${words} / ${minWords} minimum`

      // Update visual feedback
      if (isRequired) {
        if (words >= minWords) {
          counter.classList.remove('text-danger')
          counter.classList.add('text-success')
          input.classList.remove('is-invalid')
          input.classList.add('is-valid')
        } else {
          counter.classList.remove('text-success')
          counter.classList.add('text-danger')
          input.classList.remove('is-valid')
          input.classList.add('is-invalid')
        }
      }
    })
  }

  countWords(str) {
    return str.trim().split(/\s+/).filter(word => word.length > 0).length
  }
}

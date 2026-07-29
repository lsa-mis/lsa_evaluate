import { Controller } from "@hotwired/stimulus"

// Copies text from a target input/element to the clipboard
export default class extends Controller {
  static targets = ["source", "feedback"]
  static values = { successMessage: { type: String, default: "Copied!" } }

  async copy(event) {
    event.preventDefault()
    const text = this.sourceTarget.value || this.sourceTarget.textContent

    try {
      await navigator.clipboard.writeText(text)
      this.showFeedback(this.successMessageValue)
    } catch (_error) {
      this.sourceTarget.select?.()
      this.showFeedback("Select and copy manually")
    }
  }

  showFeedback(message) {
    if (!this.hasFeedbackTarget) return

    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.remove("d-none")
    window.setTimeout(() => {
      this.feedbackTarget.classList.add("d-none")
    }, 2000)
  }
}

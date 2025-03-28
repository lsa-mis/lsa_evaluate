import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    requiredInternalWords: Number,
    requiredExternalWords: Number,
    requireInternal: Boolean,
    requireExternal: Boolean,
    requiredCount: Number
  }

  validateBeforeSubmit(event) {
    event.preventDefault()

    const ratingSpace = document.querySelector('.rating-space')
    const entries = ratingSpace.querySelectorAll('[data-entry-id]')

    // Check required count
    if (entries.length !== this.requiredCountValue) {
      alert(`Please select exactly ${this.requiredCountValue} entries before finalizing.`)
      return
    }

    // Check comments
    let hasError = false
    let errorMessages = []

    entries.forEach((entry) => {
      const internalComments = entry.querySelector('textarea[name="internal_comments"]')
      const externalComments = entry.querySelector('textarea[name="external_comments"]')
      const entryTitle = entry.querySelector('.card-title').textContent

      if (this.requireInternalValue && (!internalComments || !internalComments.value.trim())) {
        errorMessages.push(`Entry "${entryTitle}" requires internal comments.`)
        hasError = true
      } else if (this.requireInternalValue) {
        const internalWords = this.countWords(internalComments.value)
        if (internalWords < this.requiredInternalWordsValue) {
          errorMessages.push(`Entry "${entryTitle}" needs at least ${this.requiredInternalWordsValue} words in internal comments (currently has ${internalWords}).`)
          hasError = true
        }
      }

      if (this.requireExternalValue && (!externalComments || !externalComments.value.trim())) {
        errorMessages.push(`Entry "${entryTitle}" requires external comments.`)
        hasError = true
      } else if (this.requireExternalValue) {
        const externalWords = this.countWords(externalComments.value)
        if (externalWords < this.requiredExternalWordsValue) {
          errorMessages.push(`Entry "${entryTitle}" needs at least ${this.requiredExternalWordsValue} words in external comments (currently has ${externalWords}).`)
          hasError = true
        }
      }
    })

    if (hasError) {
      alert("Please fix the following issues before finalizing:\n\n" + errorMessages.join("\n"))
      return
    }

    // If all validations pass, show confirmation dialog
    const confirmMessage = "Are you sure you want to finalize your rankings?\n\n" +
                         "By clicking OK, you confirm that:\n" +
                         "1. Your rankings are final\n" +
                         "2. You will no longer be able to modify entries or comments\n" +
                         "3. Your rankings will be submitted for final review\n\n" +
                         "This action cannot be undone."

    if (confirm(confirmMessage)) {
      event.target.submit()
    }
  }

  countWords(str) {
    return str.trim().split(/\s+/).filter(word => word.length > 0).length
  }
}

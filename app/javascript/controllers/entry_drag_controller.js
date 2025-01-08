import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String,
    requiredCount: { type: Number, default: 0 }
  }

  connect() {
    // Check if any entries are finalized
    const ratingSpace = document.querySelector('.rating-space')
    const hasFinalized = ratingSpace.querySelector('.alert-info')?.textContent.includes('finalized')

    // If entries are finalized, disable drag and drop
    if (hasFinalized) {
      return
    }

    this.sortable = Sortable.create(this.element, {
      group: "entries",
      animation: 150,
      ghostClass: "entry-ghost",
      dragClass: "entry-drag",
      chosenClass: "entry-chosen",
      onAdd: this.handleAdd.bind(this),
      onEnd: this.handleDragEnd.bind(this)
    })

    // Add event listeners for comment changes
    this.element.addEventListener('change', this.handleCommentChange.bind(this))
  }

  handleAdd(event) {
    if (event.to.classList.contains('rating-space')) {
      const currentCount = event.to.querySelectorAll('[data-entry-id]').length
      if (currentCount > this.requiredCountValue) {
        event.cancel = true
        const errorMessage = document.createElement('div')
        errorMessage.className = 'alert alert-danger position-fixed top-0 start-50 translate-middle-x mt-3'
        errorMessage.style.zIndex = '1050'
        errorMessage.textContent = `You can only select up to ${this.requiredCountValue} entries.`
        document.body.appendChild(errorMessage)
        setTimeout(() => errorMessage.remove(), 3000)
        return
      }
    }
  }

  handleCommentChange(event) {
    if (event.target.matches('textarea') && !event.target.readOnly) {
      this.updateRankings()
    }
  }

  handleDragEnd(event) {
    // Find the rating-space element
    const ratingSpace = document.querySelector('.rating-space')
    if (!ratingSpace) return

    this.updateRankings(ratingSpace)
  }

  updateRankings(ratingSpace = null) {
    // If ratingSpace wasn't passed, try to find it
    if (!ratingSpace) {
      ratingSpace = document.querySelector('.rating-space')
      if (!ratingSpace) return
    }

    const entries = Array.from(ratingSpace.querySelectorAll('[data-entry-id]'))
    const rankings = entries.map((entry, index) => {
      const internalComments = entry.querySelector('textarea[name="internal_comments"]')?.value || ''
      const externalComments = entry.querySelector('textarea[name="external_comments"]')?.value || ''

      return {
        entry_id: entry.dataset.entryId,
        rank: index + 1,
        internal_comments: internalComments,
        external_comments: externalComments
      }
    })

    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ rankings })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to update rankings')
      }
      return response.text()
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error:', error)
      const errorMessage = document.createElement('div')
      errorMessage.className = 'alert alert-danger position-fixed top-0 start-50 translate-middle-x mt-3'
      errorMessage.style.zIndex = '1050'
      errorMessage.textContent = error.message
      document.body.appendChild(errorMessage)
      setTimeout(() => errorMessage.remove(), 3000)
    })
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["availableEntries", "ratedEntries", "counter", "finalizeButton"]
  static values = {
    url: String,
    requiredCount: Number,
    finalized: { type: Boolean, default: false }
  }

  connect() {
    // Get the contest instance ID from the closest accordion section
    const accordionSection = this.element.closest('.accordion-collapse')
    this.contestGroupName = `entries-${accordionSection.id}`

    this.initializeSortable()
    this.initializeCommentListeners()

    // Restore accordion state if it exists
    const accordionId = accordionSection.id
    const isExpanded = sessionStorage.getItem(`accordion-${accordionId}`)
    if (isExpanded === 'true') {
      accordionSection.classList.add('show')
      const accordionButton = document.querySelector(`[data-bs-target="#${accordionId}"]`)
      if (accordionButton) {
        accordionButton.classList.remove('collapsed')
      }
    }
  }

  initializeSortable() {
    const commonOptions = {
      group: {
        name: this.contestGroupName,
        pull: !this.finalizedValue,
        put: !this.finalizedValue
      },
      animation: 150,
      ghostClass: 'entry-ghost',
      dragClass: 'entry-drag',
      chosenClass: 'entry-chosen',
      handle: '.drag-handle',
      onEnd: this.handleSortEnd.bind(this),
      onMove: this.handleMove.bind(this),
      disabled: this.finalizedValue
    }

    // Initialize sortable for available entries
    this.availableSortable = new Sortable(this.availableEntriesTarget, commonOptions)

    // Initialize sortable for rated entries
    this.ratedSortable = new Sortable(this.ratedEntriesTarget, commonOptions)

    // If finalized, update UI to reflect finalized state
    if (this.finalizedValue) {
      this.disableDragging()
    }
  }

  handleMove(event) {
    // Prevent dragging if finalized
    if (this.finalizedValue) {
      return false
    }

    // Get the contest instance IDs from the source and target containers
    const sourceAccordion = event.from.closest('.accordion-collapse')
    const targetAccordion = event.to.closest('.accordion-collapse')

    // Prevent dragging if the source and target are from different contest instances
    if (sourceAccordion.id !== targetAccordion.id) {
      return false
    }

    return true
  }

  async handleSortEnd(event) {
    // Save accordion state before refresh
    const accordionSection = this.element.closest('.accordion-collapse')
    const accordionId = accordionSection.id
    sessionStorage.setItem(`accordion-${accordionId}`, accordionSection.classList.contains('show'))

    // Get all entries in both areas
    const rankings = []

    // First, mark all entries as unranked
    const availableEntries = Array.from(this.availableEntriesTarget.querySelectorAll('.card[data-entry-id]'))
    availableEntries.forEach(element => {
      const entryId = element.dataset.entryId
      if (entryId) {
        rankings.push({
          entry_id: entryId,
          rank: null,
          internal_comments: null,
          external_comments: null
        })
      }
    })

    // Then, add ranked entries with their positions and comments
    const ratedEntries = Array.from(this.ratedEntriesTarget.querySelectorAll('.card[data-entry-id]'))
    ratedEntries.forEach((element, index) => {
      const entryId = element.dataset.entryId
      if (entryId) {
        const internalComments = element.querySelector('textarea[name="internal_comments"]')?.value || ''
        const externalComments = element.querySelector('textarea[name="external_comments"]')?.value || ''

        // Update the rank badge immediately
        const rankBadge = element.querySelector('.badge.bg-info')
        if (rankBadge) {
          rankBadge.textContent = `Rank: ${index + 1}`
        }

        // Remove any existing entry for this ID (from available entries)
        const existingIndex = rankings.findIndex(r => r.entry_id === entryId)
        if (existingIndex !== -1) {
          rankings.splice(existingIndex, 1)
        }

        // Add the complete entry data
        rankings.push({
          entry_id: entryId,
          rank: index + 1,
          internal_comments: internalComments.trim(),
          external_comments: externalComments.trim()
        })
      }
    })

    // Update UI immediately
    this.updateUI(ratedEntries.length)

    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ rankings })
      })

      if (!response.ok) {
        throw new Error('Network response was not ok')
      }

      const data = await response.json()
      if (!data.success) {
        throw new Error(data.error || 'Failed to update rankings')
      }

      // Refresh both sections using Turbo
      Turbo.visit(window.location.href, { action: "replace" })
    } catch (error) {
      console.error('Error updating rankings:', error)
      // If there's an error, revert the UI update
      this.updateUI(this.ratedEntriesTarget.children.length)
    }
  }

  updateUI(ratedCount) {
    // Update counter if it exists
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${ratedCount}/${this.requiredCountValue}`
    }

    // Update rank badges
    const ratedEntries = Array.from(this.ratedEntriesTarget.querySelectorAll('.card[data-entry-id]'))
    ratedEntries.forEach((element, index) => {
      const rankBadge = element.querySelector('.badge.bg-info')
      if (rankBadge) {
        rankBadge.textContent = `Rank: ${index + 1}`
      }
    })

    // Update submit button state if it exists
    if (this.hasFinalizeButtonTarget) {
      this.finalizeButtonTarget.disabled = ratedCount !== this.requiredCountValue || this.finalizedValue
    }
  }

  disableDragging() {
    // Disable drag handles visually
    this.element.querySelectorAll('.drag-handle').forEach(handle => {
      handle.style.cursor = 'not-allowed'
      handle.style.opacity = '0.5'
    })

    // Disable sortable functionality
    this.availableSortable.option('disabled', true)
    this.ratedSortable.option('disabled', true)

    // Update button state
    if (this.hasFinalizeButtonTarget) {
      this.finalizeButtonTarget.disabled = true
    }
  }

  finalizedValueChanged() {
    if (this.finalizedValue) {
      this.disableDragging()
    }
  }

  initializeCommentListeners() {
    // Add event listeners for comment changes
    this.ratedEntriesTarget.addEventListener('blur', (event) => {
      if (event.target.matches('textarea[name="internal_comments"], textarea[name="external_comments"]')) {
        this.handleCommentChange(event)
      }
    }, true) // Use capture phase to ensure we catch the blur event
  }

  async handleCommentChange(event) {
    const textarea = event.target
    const entryCard = textarea.closest('[data-entry-id]')
    const entryId = entryCard.dataset.entryId
    const isInternal = textarea.name === 'internal_comments'

    // Show saving indicator
    const savingIndicator = document.createElement('small')
    savingIndicator.className = 'text-muted ms-2 saving-indicator'
    savingIndicator.textContent = 'Saving...'
    textarea.parentElement.querySelector('.form-label').appendChild(savingIndicator)

    // Get just this entry's data
    const internalComments = entryCard.querySelector('textarea[name="internal_comments"]')?.value || ''
    const externalComments = entryCard.querySelector('textarea[name="external_comments"]')?.value || ''
    const rank = Array.from(this.ratedEntriesTarget.querySelectorAll('.card[data-entry-id]')).findIndex(el => el.dataset.entryId === entryId) + 1

    // Only send the updated entry
    const rankings = [{
      entry_id: entryId,
      rank: rank,
      internal_comments: internalComments.trim(),
      external_comments: externalComments.trim()
    }]

    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ rankings })
      })

      if (!response.ok) {
        throw new Error('Network response was not ok')
      }

      // Update saving indicator to show success briefly
      savingIndicator.textContent = 'Saved!'
      savingIndicator.className = 'text-success ms-2 saving-indicator'
      setTimeout(() => {
        savingIndicator.remove()
      }, 2000)
    } catch (error) {
      console.error('Error saving comments:', error)
      // Update saving indicator to show error
      savingIndicator.textContent = 'Failed to save. Please try again.'
      savingIndicator.className = 'text-danger ms-2 saving-indicator'
      setTimeout(() => {
        savingIndicator.remove()
      }, 3000)
    }
  }
}

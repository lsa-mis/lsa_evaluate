import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["availableEntries", "ratedEntries", "counter", "finalizeButton"]
  static values = {
    url: String,
    requiredCount: Number,
    finalized: { type: Boolean, default: false }
  }

  connect() {
    // Add a style block for the loading overlay if it doesn't exist
    if (!document.getElementById('entry-drag-styles')) {
      const style = document.createElement('style')
      style.id = 'entry-drag-styles'
      style.textContent = `
        .entry-loading-overlay {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(255, 255, 255, 0);
          display: flex;
          justify-content: center;
          align-items: center;
          z-index: 1000;
          opacity: 0;
          transition: all 0.3s ease;
        }

        .entry-loading-overlay.show {
          background: rgba(255, 255, 255, 0.8);
          opacity: 1;
        }

        .entry-loading-overlay.error {
          background: rgba(255, 220, 220, 0.9);
        }

        .entry-loading-overlay .spinner-container {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 0.5rem;
        }

        .entry-loading-overlay .status-text {
          font-size: 0.875rem;
          color: #666;
          text-align: center;
          margin-top: 0.5rem;
        }

        .entry-loading-overlay .error-text {
          color: #dc3545;
          font-weight: 500;
        }

        .entry-loading-overlay .warning-text {
          color: #ffc107;
          font-weight: 500;
        }

        .entry-loading-overlay.success {
          background: rgba(220, 255, 220, 0.95);
        }

        .entry-loading-overlay .success-text {
          color: #198754;
          font-weight: 500;
        }

        .card.entry-card-loading {
          overflow: visible;
        }

        .card.entry-card-loading .entry-loading-overlay {
          z-index: 9999;
        }

        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      `
      document.head.appendChild(style)
    }

    // Get the contest instance ID from the closest accordion section
    const accordionSection = this.element.closest('.accordion-collapse')
    if (!accordionSection) {
      console.error('No accordion section found for entry drag controller')
      return
    }

    this.contestGroupName = `entries-${accordionSection.id}`
    this.accordionSection = accordionSection
    this.slowConnectionTimeouts = new WeakMap()

    this.initializeSortable()
    this.initializeCommentListeners()

    // Restore accordion state and scroll position if they exist
    const accordionId = accordionSection.id
    const isExpanded = sessionStorage.getItem(`accordion-${accordionId}`)

    // Initialize the accordion with the stored state
    if (isExpanded !== null) {  // Check if there's a stored state
      const accordionButton = document.querySelector(`[data-bs-target="#${accordionId}"]`)
      if (isExpanded === 'true') {
        accordionSection.classList.add('show')
        if (accordionButton) {
          accordionButton.classList.remove('collapsed')
        }
      } else {
        accordionSection.classList.remove('show')
        if (accordionButton) {
          accordionButton.classList.add('collapsed')
        }
      }

      // Restore scroll position if accordion is open
      if (isExpanded === 'true') {
        const scrollPosition = sessionStorage.getItem(`scroll-${accordionId}`)
        if (scrollPosition) {
          requestAnimationFrame(() => {
            window.scrollTo(0, parseInt(scrollPosition))
            sessionStorage.removeItem(`scroll-${accordionId}`)
          })
        }
      }
    }

    // Add event listeners for accordion state changes
    accordionSection.addEventListener('show.bs.collapse', () => {
      sessionStorage.setItem(`accordion-${accordionId}`, 'true')
    })

    accordionSection.addEventListener('hide.bs.collapse', () => {
      sessionStorage.setItem(`accordion-${accordionId}`, 'false')
    })
  }

  initializeSortable() {
    if (!this.hasAvailableEntriesTarget || !this.hasRatedEntriesTarget) return

    // Add a property to store the confirmation result
    this.moveConfirmed = true

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
      onStart: this.handleStart.bind(this),
      onMove: this.handleMove.bind(this),
      onEnd: this.handleSortEnd.bind(this),
      disabled: this.finalizedValue,
      // Ensure dragging only works within the same accordion section
      filter: (event, target) => {
        const targetAccordion = target.closest('.accordion-collapse')
        return targetAccordion && targetAccordion.id !== this.accordionSection.id
      }
    }

    // Initialize sortable for available entries
    this.availableSortable = new Sortable(this.availableEntriesTarget, {
      ...commonOptions,
      sort: false // Prevent sorting within available entries
    })

    // Initialize sortable for rated entries
    this.ratedSortable = new Sortable(this.ratedEntriesTarget, commonOptions)

    // If finalized, update UI to reflect finalized state
    if (this.finalizedValue) {
      this.disableDragging()
    }
  }

  handleStart(event) {
    // Reset confirmation for new drag operation
    this.moveConfirmed = true

    // Add loading overlay to the dragged card
    const card = event.item
    this.addLoadingOverlay(card)
  }

  handleMove(event) {
    // First check if we're trying to drag between different contest instances
    const fromAccordion = event.from.closest('.accordion-collapse')
    const toAccordion = event.to.closest('.accordion-collapse')
    if (fromAccordion && toAccordion && fromAccordion.id !== toAccordion.id) {
      this.removeLoadingOverlay(event.item)
      return false
    }

    // If moving from rated to available entries, show confirmation dialog
    if (event.from === this.ratedEntriesTarget && event.to === this.availableEntriesTarget) {
      if (!this.moveConfirmed) {
        this.moveConfirmed = confirm("Are you sure you want to unrank this entry? Any comments you have written will be deleted.")
      }
      if (!this.moveConfirmed) {
        this.removeLoadingOverlay(event.item)
      }
      return this.moveConfirmed
    }
    return true
  }

  async handleSortEnd(event) {
    // If this was a drag operation and it wasn't confirmed, return the item to its original position
    if (!this.moveConfirmed && event.from === this.ratedEntriesTarget && event.to === this.availableEntriesTarget) {
      event.from.appendChild(event.item)
      this.removeLoadingOverlay(event.item)
      return
    }

    // Reset confirmation state
    this.moveConfirmed = false

    // Save accordion state and scroll position before refresh
    const accordionSection = this.element.closest('.accordion-collapse')
    const accordionId = accordionSection.id
    sessionStorage.setItem(`accordion-${accordionId}`, accordionSection.classList.contains('show'))
    sessionStorage.setItem(`scroll-${accordionId}`, window.scrollY.toString())

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

      // Show success state so judges see "Ranking recorded" before refresh
      this.showSuccessOverlay(event.item)

      setTimeout(() => {
        this.removeLoadingOverlay(event.item)
        Turbo.visit(window.location.href, { action: "replace" })
      }, 2500)
    } catch (error) {
      console.error('Error updating rankings:', error)
      // If there's an error, revert the UI update and show error in overlay
      this.updateUI(this.ratedEntriesTarget.children.length)
      this.removeLoadingOverlay(event.item, true)
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

    // Ensure Sortable instances exist before trying to disable them
    if (this.availableSortable) {
      this.availableSortable.option('disabled', true)
    }
    if (this.ratedSortable) {
      this.ratedSortable.option('disabled', true)
    }

    // Update button state
    if (this.hasFinalizeButtonTarget) {
      this.finalizeButtonTarget.disabled = true
    }
  }

  finalizedValueChanged() {
    if (this.finalizedValue) {
      // Ensure Sortable instances are initialized before disabling
      if (!this.availableSortable || !this.ratedSortable) {
        this.initializeSortable()
      }
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

  async addToRanked(event) {
    if (this.finalizedValue) return

    const entryCard = event.target.closest('.card[data-entry-id]')
    if (!entryCard) return

    // Show loading overlay just like drag-and-drop (before moving so overlay moves with card)
    this.addLoadingOverlay(entryCard)

    // Move the card to rated entries (card may be inside a turbo-frame; we move the card node)
    this.ratedEntriesTarget.appendChild(entryCard)
    entryCard.scrollIntoView({ behavior: 'smooth', block: 'nearest' })

    await this.handleSortEnd({ from: this.availableEntriesTarget, to: this.ratedEntriesTarget, item: entryCard })
  }

  async removeFromRanked(event) {
    if (this.finalizedValue) return

    const entryCard = event.target.closest('.card[data-entry-id]')
    if (!entryCard) return

    // Show confirmation dialog
    if (!confirm("Are you sure you want to unrank this entry? Any comments you have written will be deleted.")) {
      return
    }

    // Show loading overlay just like drag-and-drop (before moving so overlay moves with card)
    this.addLoadingOverlay(entryCard)

    // Move the card back to available entries
    this.availableEntriesTarget.appendChild(entryCard)
    entryCard.scrollIntoView({ behavior: 'smooth', block: 'nearest' })

    await this.handleSortEnd({ from: this.ratedEntriesTarget, to: this.availableEntriesTarget, item: entryCard })
  }

  // Helper method to add loading overlay
  addLoadingOverlay(element) {
    if (!element) return

    // Prevent multiple overlays
    if (element.querySelector('.entry-loading-overlay')) {
      return
    }

    const overlay = document.createElement('div')
    overlay.className = 'entry-loading-overlay'
    overlay.innerHTML = `
      <div class="spinner-container" role="status" aria-live="polite">
        <div class="spinner-border text-primary" role="presentation"></div>
        <div class="status-text">Updating...</div>
      </div>
    `

    // Ensure the card has position relative and won't clip the overlay
    element.style.position = 'relative'
    element.classList.add('entry-card-loading')
    element.appendChild(overlay)

    // Show overlay immediately so it's visible for button clicks (card is about to move)
    overlay.classList.add('show')

    // Set up slow connection warning (per-element so multiple overlays clean up correctly)
    const timeoutId = setTimeout(() => {
      const statusText = overlay.querySelector('.status-text')
      if (statusText) {
        statusText.innerHTML = `
          <span class="warning-text">
            <i class="bi bi-exclamation-triangle-fill"></i>
            Slow connection detected...
          </span>
          <br>
          Still working...
          <br>
          <small>Please wait for "Ranking recorded" before closing or navigating away.</small>
        `
      }
    }, 5000) // Show warning after 5 seconds
    this.slowConnectionTimeouts.set(element, timeoutId)
  }

  // Helper method to show success state on the overlay before removing it
  showSuccessOverlay(element) {
    if (!element) return

    const overlay = element.querySelector('.entry-loading-overlay')
    if (!overlay) return

    const timeoutId = this.slowConnectionTimeouts.get(element)
    if (timeoutId) {
      clearTimeout(timeoutId)
      this.slowConnectionTimeouts.delete(element)
    }

    overlay.classList.add('success')
    const spinnerContainer = overlay.querySelector('.spinner-container')
    if (spinnerContainer) {
      spinnerContainer.innerHTML = `
        <i class="bi bi-check-circle-fill text-success" style="font-size: 2rem;" aria-hidden="true"></i>
        <div class="status-text success-text">Ranking recorded</div>
      `
    }
  }

  // Helper method to remove loading overlay
  removeLoadingOverlay(element, error = false) {
    if (!element) return

    const overlay = element.querySelector('.entry-loading-overlay')
    if (!overlay) return

    element.classList.remove('entry-card-loading')

    // Clear slow connection timeout for this element
    const timeoutId = this.slowConnectionTimeouts.get(element)
    if (timeoutId) {
      clearTimeout(timeoutId)
      this.slowConnectionTimeouts.delete(element)
    }

    if (error) {
      overlay.classList.add('error')
      const statusText = overlay.querySelector('.status-text')
      if (statusText) {
        statusText.innerHTML = `
          <span class="error-text">
            <i class="bi bi-x-circle-fill"></i>
            Error updating entry
          </span>
          <br>
          Please try again
        `
      }
      // Remove error overlay after 2 seconds
      setTimeout(() => {
        overlay.classList.remove('show')
        setTimeout(() => overlay.remove(), 300)
      }, 2000)
    } else {
      overlay.classList.remove('show')
      // Remove overlay after transition completes
      setTimeout(() => overlay.remove(), 300)
    }
  }
}

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
    // Get all entries in both areas
    const allEntries = new Map()

    // First, mark all entries as unranked
    const availableEntries = Array.from(this.availableEntriesTarget.children)
    availableEntries.forEach(element => {
      allEntries.set(element.dataset.entryId, {
        entry_id: element.dataset.entryId,
        rank: null
      })
    })

    // Then, add ranked entries with their positions
    const ratedEntries = Array.from(this.ratedEntriesTarget.children)
    ratedEntries.forEach((element, index) => {
      allEntries.set(element.dataset.entryId, {
        entry_id: element.dataset.entryId,
        rank: index + 1
      })
    })

    // Update UI immediately
    this.updateUI(ratedEntries.length)

    // Convert the map to an array of rankings
    const rankings = Array.from(allEntries.values())

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
        // If there's an error, revert the UI update
        this.updateUI(this.ratedEntriesTarget.children.length)
      }
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
}

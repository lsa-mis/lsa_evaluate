import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["availableEntries", "ratedEntries"]
  static values = {
    url: String,
    requiredCount: Number
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
        pull: true,
        put: true
      },
      animation: 150,
      ghostClass: 'entry-ghost',
      dragClass: 'entry-drag',
      chosenClass: 'entry-chosen',
      handle: '.drag-handle',
      onEnd: this.handleSortEnd.bind(this),
      onMove: this.handleMove.bind(this)
    }

    // Initialize sortable for available entries
    this.availableSortable = new Sortable(this.availableEntriesTarget, commonOptions)

    // Initialize sortable for rated entries
    this.ratedSortable = new Sortable(this.ratedEntriesTarget, commonOptions)
  }

  handleMove(event) {
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
      }

      // Update UI elements after successful save
      this.updateUI(ratedEntries.length)
    } catch (error) {
      console.error('Error updating rankings:', error)
    }
  }

  updateUI(ratedCount) {
    // Update counter if it exists
    const counter = document.querySelector('.rated-entries-counter')
    if (counter) {
      counter.textContent = `${ratedCount}/${this.requiredCountValue}`
    }

    // Update submit button state if it exists
    const submitButton = document.querySelector('.finalize-rankings-btn')
    if (submitButton) {
      submitButton.disabled = ratedCount !== this.requiredCountValue
    }
  }
}

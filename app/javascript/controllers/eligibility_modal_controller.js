// app/javascript/controllers/eligibility_modal_controller.js

import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["content", "modal", "closeButton", "mainContent"]
  static values = {
    loaded: { type: Object, default: {} }
  }

  initialize() {
    this.handleKeyDown = this.handleKeyDown.bind(this)
  }

  connect() {
    // Initialize Bootstrap Modal using the modal target
    this.modal = new Modal(this.modalTarget, {
      backdrop: true,
      keyboard: true,
      focus: false // We'll handle focus manually
    })

    // Store the element that had focus before the modal was opened
    this.previouslyFocusedElement = null
    this.isLoaded = {}

    // Add event listeners for modal events
    this.modalTarget.addEventListener('show.bs.modal', this.handleModalShow.bind(this))
    this.modalTarget.addEventListener('shown.bs.modal', this.handleModalShown.bind(this))
    this.modalTarget.addEventListener('hide.bs.modal', this.handleModalHide.bind(this))
    this.modalTarget.addEventListener('hidden.bs.modal', this.handleModalHidden.bind(this))
    this.modalTarget.addEventListener('keydown', this.handleKeyDown)
  }

  disconnect() {
    console.log("Eligibility modal controller disconnected")
    if (this.modal) {
      this.modal.dispose()
    }
    // Clean up event listeners
    this.modalTarget.removeEventListener('show.bs.modal', this.handleModalShow.bind(this))
    this.modalTarget.removeEventListener('shown.bs.modal', this.handleModalShown.bind(this))
    this.modalTarget.removeEventListener('hide.bs.modal', this.handleModalHide.bind(this))
    this.modalTarget.removeEventListener('hidden.bs.modal', this.handleModalHidden.bind(this))
    this.modalTarget.removeEventListener('keydown', this.handleKeyDown)
  }

  handleKeyDown(event) {
    if (event.key === 'Escape') {
      event.preventDefault()
      this.modal.hide()
    }
  }

  handleModalShow() {
    // Store the previously focused element
    this.previouslyFocusedElement = document.activeElement

    // Remove inert from modal and add it to main content
    this.modalTarget.removeAttribute('inert')
    if (this.hasMainContentTarget) {
      this.mainContentTarget.setAttribute('inert', '')
    }
  }

  handleModalShown() {
    // Focus the close button
    if (this.hasCloseButtonTarget) {
      this.closeButtonTarget.focus()
    }
  }

  handleModalHide() {
    // Add inert back to modal
    this.modalTarget.setAttribute('inert', '')

    // Remove inert from main content
    if (this.hasMainContentTarget) {
      this.mainContentTarget.removeAttribute('inert')
    }
  }

  handleModalHidden() {
    // Restore focus to the previously focused element
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus()
    }
  }

  open(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.url

    // Check if content is already loaded
    if (this.isLoaded[url]) {
      this.contentTarget.innerHTML = this.isLoaded[url]
      this.modal.show()
      return
    }

    // Show a loading spinner
    this.contentTarget.innerHTML = `
      <div class="d-flex justify-content-center">
        <div class="spinner-border" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
      </div>
    `
    this.modal.show()

    // Fetch the eligibility rules
    fetch(url, {
      headers: {
        "Accept": "text/html"
      }
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.text()
      })
      .then(html => {
        // Parse the HTML string into a DOM object
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")

        // Modify all <a> tags
        doc.querySelectorAll('a').forEach(link => {
          link.setAttribute('target', '_blank')
          link.setAttribute('rel', 'noopener noreferrer')
        })

        // Serialize the modified DOM back to a string
        const modifiedHtml = doc.body.innerHTML

        // Set the modified HTML as the content
        this.contentTarget.innerHTML = modifiedHtml
        this.isLoaded[url] = modifiedHtml // Cache the content
      })
      .catch(error => {
        console.error(error)
        this.contentTarget.innerHTML = "<p>Error loading content.</p>"
      })
  }
}

import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["content", "modal", "closeButton", "mainContent", "title"]
  static values = {
    loaded: { type: Object, default: {} }
  }

  initialize() {
    this.handleKeyDown = this.handleKeyDown.bind(this)
  }

  connect() {
    this.modal = new Modal(this.modalTarget, {
      backdrop: true,
      keyboard: true,
      focus: false
    })

    this.previouslyFocusedElement = null
    this.isLoaded = {}

    this.modalTarget.addEventListener('show.bs.modal', this.handleModalShow.bind(this))
    this.modalTarget.addEventListener('shown.bs.modal', this.handleModalShown.bind(this))
    this.modalTarget.addEventListener('hide.bs.modal', this.handleModalHide.bind(this))
    this.modalTarget.addEventListener('hidden.bs.modal', this.handleModalHidden.bind(this))
    this.modalTarget.addEventListener('keydown', this.handleKeyDown)
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose()
    }

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
    this.previouslyFocusedElement = document.activeElement
    this.modalTarget.removeAttribute('inert')
    if (this.hasMainContentTarget) {
      this.mainContentTarget.setAttribute('inert', '')
    }
  }

  handleModalShown() {
    if (this.hasCloseButtonTarget) {
      this.closeButtonTarget.focus()
    }
  }

  handleModalHide() {
    this.modalTarget.setAttribute('inert', '')
    if (this.hasMainContentTarget) {
      this.mainContentTarget.removeAttribute('inert')
    }
  }

  handleModalHidden() {
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus()
    }
  }

  open(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.url
    const title = event.currentTarget.dataset.modalTitle || 'Details'

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title
    }

    if (this.isLoaded[url]) {
      this.contentTarget.innerHTML = this.isLoaded[url]
      this.modal.show()
      return
    }

    this.contentTarget.innerHTML = `
      <div class="d-flex justify-content-center">
        <div class="spinner-border" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
      </div>
    `
    this.modal.show()

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
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")

        doc.querySelectorAll('a').forEach(link => {
          link.setAttribute('target', '_blank')
          link.setAttribute('rel', 'noopener noreferrer')
        })

        const modifiedHtml = doc.body.innerHTML
        this.contentTarget.innerHTML = modifiedHtml
        this.isLoaded[url] = modifiedHtml
      })
      .catch(error => {
        console.error(error)
        this.contentTarget.innerHTML = "<p>Error loading content.</p>"
      })
  }
}

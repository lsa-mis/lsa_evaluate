// app/javascript/controllers/eligibility_modal_controller.js

import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["content", "modal"]

  connect() {
    // Initialize Bootstrap Modal using the modal target
    this.modal = new Modal(this.modalTarget)
    this.isLoaded = {}
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
        this.contentTarget.innerHTML = html
        this.isLoaded[url] = html // Cache the content
      })
      .catch(error => {
        this.contentTarget.innerHTML = "<p>Error loading content.</p>"
      })
  }
}
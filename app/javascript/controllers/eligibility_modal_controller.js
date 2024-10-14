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
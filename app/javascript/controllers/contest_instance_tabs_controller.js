import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.location.hash) {
      this.scrollToAnchor()
    }
  }

  scrollToAnchor() {
    const target = document.querySelector(window.location.hash)
    target?.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}

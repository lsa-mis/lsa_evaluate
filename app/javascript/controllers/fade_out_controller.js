// app/javascript/controllers/fade_out_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:before-stream-render", this.fadeOut)
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-stream-render", this.fadeOut)
  }

  fadeOut = (event) => {
    const action = event.detail.newStream.element.getAttribute("action")
    if (action === "remove") {
      this.element.classList.add("fade-out")
      event.preventDefault()
      setTimeout(() => {
        this.element.remove()
      }, 500) // Duration matches the CSS transition
    }
  }
}
// app/javascript/controllers/fade_out_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Directly apply fade out when the controller connects (for testing purposes)
    setTimeout(() => {
      this.element.classList.add("fade-out")
      setTimeout(() => {
        this.element.remove() // Remove the element after fading out
      }, 500) // This duration should match the CSS transition duration
    }, 3000) // Wait 3 seconds before starting the fade-out
  }
}
// app/javascript/controllers/scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    scrollToTop: Boolean
  }

  connect() {
    if (this.scrollToTopValue) {
      window.scrollTo(0, 0)
    }
  }
}
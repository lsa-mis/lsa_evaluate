// app/javascript/controllers/scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
      console.log("connect - scroll")
  }

  scrollToTopIfSuccessful(event) {
    if (event.detail.success) {
      window.scrollTo(0, 0)
    }
  }
}
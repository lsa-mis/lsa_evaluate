import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    console.log("connect");
    this.timeout = setTimeout(() => { this.dismiss(); }, 5000);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }

  dismiss() {
    console.log("dismiss");
    try {
      this.element.remove();
    } catch (error) {
      console.error("Error removing element:", error);
    }
  }
}
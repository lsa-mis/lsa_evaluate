import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log("Interaction controller connected");
  }

  async showEntrantContent(event) {
    event.preventDefault();
    const response = await fetch('/static_pages/entrant_content');
    const html = await response.text();
    this.contentTarget.innerHTML = html;
  }

  async showAdminContent(event) {
    event.preventDefault();
    const response = await fetch('/static_pages/admin_content');
    const html = await response.text();
    this.contentTarget.innerHTML = html;
  }
}
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown controller connected");
  }
  
  toggle(event) {
    this.menuTarget.classList.toggle('show');  // Toggle the 'show' class on the dropdown menu
    event.stopPropagation();  // Prevent the event from propagating to the document
  }
}

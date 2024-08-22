// app/javascript/controllers/nested_form_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["template", "container"]

  connect() {
    console.log("Nested_form controller connected");
  }

  addAssociation(event) {
    event.preventDefault();

    // Get the time for unique IDs
    const time = new Date().getTime();
    const regex = new RegExp("new_category_contest_instances", "g");

    // Clone the template content
    const content = this.templateTarget.innerHTML.replace(regex, time);

    // Append the new content to the container
    this.containerTarget.insertAdjacentHTML('beforeend', content);
  }

  removeAssociation(event) {
    event.preventDefault();

    // Find the closest nested field wrapper and remove it
    const wrapper = event.target.closest('.nested-fields');
    if (wrapper) {
      wrapper.remove();
    }
  }
}
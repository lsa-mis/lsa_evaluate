// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["loading", "submitButton"]

  connect() {
    this.element.addEventListener('turbo:submit-start', this.showLoading.bind(this));
  }

  showLoading() {
    this.loadingTarget.style.display = "block";
    this.submitButtonTarget.disabled = true; 
    this.submitButtonTarget.classList.add('disabled'); // Disable the submit button
  }
}
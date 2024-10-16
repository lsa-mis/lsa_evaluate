// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["loading", "submitButton"]

  connect() {
    this.element.addEventListener('turbo:submit-start', this.showLoading.bind(this));
    console.log("Form submission controller connected");
  }

  showLoading() {
    console.log("started") // Show the loading spinner
    this.loadingTarget.style.display = "block";
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.classList.add('disabled');
    console.log("finished") // Disable the submit button
  }
}
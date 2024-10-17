// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["loading", "submitButton"]

  connect() {
    // console.log("Form submission controller connected");
  }

  showLoading(event) {
    // console.log("Form submission started");
    this.loadingTarget.classList.remove("d-none");
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.classList.add('disabled');
    // console.log("Spinner displayed and submit button disabled");
  }
}
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox_all", "checkbox", "form", "date_open", "date_closed"]

  connect() {
    this.checkboxTargets.map(x => x.checked = false)
    this.checkbox_allTarget.checked = false
  }

  toggleCheckbox() {
    this.clearErrorMessage();
    const isChecked = this.checkbox_allTarget.checked;
    this.checkboxTargets.forEach(checkbox => checkbox.checked = isChecked);
  }

  toggleCheckboxAll() {
    this.clearErrorMessage();
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked);
    this.checkbox_allTarget.checked = allChecked;
  }

  submitForm(event) {
    this.clearErrorMessage();
    const date_open = this.date_openTarget.value;
    const date_closed = this.date_closedTarget.value;
    let errorMessage = '';

    if (!date_open || !date_closed) {
      errorMessage = "Please select dates. ";
    } else if (date_open > date_closed) {
      errorMessage = "Date Open should occur before Date Closed. ";
    }

    if (!this.checkboxTargets.some(checkbox => checkbox.checked)) {
      errorMessage += "Please select descriptions.";
    }

    if (errorMessage) {
      this.setErrorMessage(errorMessage);
      event.preventDefault();
    }
  }

  clearErrorMessage() {
    const checkbox_error_place = document.getElementById('checkbox_error');
    checkbox_error_place.innerHTML = '';
  }

  setErrorMessage(message) {
    const checkbox_error_place = document.getElementById('checkbox_error');
    checkbox_error_place.innerHTML = message;
  }
}

// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["filterRow", "statusFilter"];

  connect() {
    console.log("Filter controller connected");
    this.toggleFilter(); // Apply filter on page load
  }

  toggleFilter() {
    const showOnlyActive = this.statusFilterTarget.checked;

    this.filterRowTargets.forEach((row) => {
      const isActive = row.dataset.status === "true";
      if (showOnlyActive && !isActive) {
        row.classList.add("d-none");
      } else {
        row.classList.remove("d-none");
      }
    });
  }
}
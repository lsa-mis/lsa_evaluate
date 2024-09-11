import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["filterRow", "statusFilter"]

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
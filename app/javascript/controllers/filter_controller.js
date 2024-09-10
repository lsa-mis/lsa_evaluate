import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["filterRow", "statusFilter"]

  toggleFilter() {
    const showOnlyActive = this.statusFilterTarget.checked;

    this.filterRowTargets.forEach((row) => {
      const status = row.dataset.status;
      if (showOnlyActive && status !== "Active") {
        row.classList.add("d-none");
      } else {
        row.classList.remove("d-none");
      }
    });
  }
}
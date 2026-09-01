import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "endDate",
    "startDate",
    "startDateField",
    "updateStartDateToggle",
    "previewPanel",
    "previewContent",
    "roundCheckbox",
    "roundRow",
    "cascadeToggle",
    "cascadeMode"
  ]

  static values = {
    previewUrl: String,
    singleRound: { type: Boolean, default: false }
  }

  connect() {
    this.previewTimeout = null
    if (!this.singleRoundValue) {
      this.filterActiveRounds()
    } else {
      this.schedulePreview()
    }
  }

  toggleStartDate() {
    const enabled = this.updateStartDateToggleTarget.checked
    this.startDateFieldTarget.classList.toggle("d-none", !enabled)
    this.schedulePreview()
  }

  roundSelectionChanged() {
    this.schedulePreview()
  }

  filterActiveRounds() {
    const activeOnly = document.getElementById("filter_active_only")?.checked
    this.roundRowTargets.forEach((row) => {
      const isActive = row.dataset.active === "true"
      row.classList.toggle("d-none", activeOnly && !isActive)
    })
  }

  schedulePreview() {
    clearTimeout(this.previewTimeout)
    this.previewTimeout = setTimeout(() => this.loadPreview(), 300)
  }

  async loadPreview() {
    if (!this.previewUrlValue || !this.endDateTarget.value) {
      this.hidePreview()
      return
    }

    const body = new FormData()
    body.append("end_date", this.endDateTarget.value)
    if (this.hasStartDateTarget) {
      body.append("start_date", this.startDateTarget.value)
    }
    body.append("cascade_mode", this.cascadeModeTarget?.value || "minimum_bump")

    if (!this.singleRoundValue) {
      const selectedRoundIds = this.roundCheckboxTargets
        .filter((checkbox) => checkbox.checked)
        .map((checkbox) => checkbox.value)

      if (selectedRoundIds.length === 0) {
        this.hidePreview()
        return
      }

      body.append("update_start_date", this.updateStartDateToggleTarget?.checked ? "1" : "0")
      selectedRoundIds.forEach((id) => body.append("judging_round_ids[]", id))
    }

    const response = await fetch(this.previewUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
        "Accept": "application/json"
      },
      body
    })

    if (!response.ok) {
      this.hidePreview()
      return
    }

    const data = await response.json()
    if (this.singleRoundValue) {
      this.renderSingleRoundPreview(data)
    } else {
      this.renderPreview(data.plans)
    }
  }

  renderSingleRoundPreview(plan) {
    if (!plan.conflicts) {
      this.hidePreview()
      return
    }

    const rows = plan.changes.map((change) => `
      <tr>
        <td>Round ${change.round_number}</td>
        <td>${change.field.replace("_", " ")}</td>
        <td>${change.from}</td>
        <td>${change.to}</td>
        <td>${change.reason}</td>
      </tr>
    `).join("")

    this.previewContentTarget.innerHTML = `
      <table class="table table-sm table-bordered mt-2 mb-0">
        <thead>
          <tr>
            <th>Round</th>
            <th>Field</th>
            <th>Current</th>
            <th>Proposed</th>
            <th>Reason</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `
    this.previewPanelTarget.classList.remove("d-none")
  }

  renderPreview(plans) {
    const conflictingPlans = plans.filter((plan) => plan.conflicts)
    if (conflictingPlans.length === 0) {
      this.hidePreview()
      return
    }

    const html = conflictingPlans.map((plan) => {
      const rows = plan.changes.map((change) => `
        <tr>
          <td>Round ${change.round_number}</td>
          <td>${change.field.replace("_", " ")}</td>
          <td>${change.from}</td>
          <td>${change.to}</td>
          <td>${change.reason}</td>
        </tr>
      `).join("")

      return `
        <div class="mb-3">
          <strong>${plan.contest_name}</strong> (${plan.instance_label}) — Round ${plan.round_number}
          <table class="table table-sm table-bordered mt-2 mb-0">
            <thead>
              <tr>
                <th>Round</th>
                <th>Field</th>
                <th>Current</th>
                <th>Proposed</th>
                <th>Reason</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      `
    }).join("")

    this.previewContentTarget.innerHTML = html
    this.previewPanelTarget.classList.remove("d-none")

    if (this.hasCascadeToggleTarget) {
      this.cascadeToggleTarget.checked = true
    }
  }

  hidePreview() {
    if (this.hasPreviewPanelTarget) {
      this.previewPanelTarget.classList.add("d-none")
    }
    if (this.hasPreviewContentTarget) {
      this.previewContentTarget.innerHTML = ""
    }
  }

  confirmSubmit(event) {
    if (!this.hasPreviewPanelTarget || this.previewPanelTarget.classList.contains("d-none")) {
      return
    }

    const confirmed = window.confirm(
      "This update will adjust following round dates for one or more contest instances. Continue?"
    )

    if (!confirmed) {
      event.preventDefault()
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}

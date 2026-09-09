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

    this.previewContentTarget.replaceChildren(this.buildChangesTable(plan.changes))
    this.previewPanelTarget.classList.remove("d-none")
  }

  renderPreview(plans) {
    const conflictingPlans = plans.filter((plan) => plan.conflicts)
    if (conflictingPlans.length === 0) {
      this.hidePreview()
      return
    }

    const fragment = document.createDocumentFragment()
    conflictingPlans.forEach((plan) => {
      fragment.appendChild(this.buildPlanPreview(plan))
    })

    this.previewContentTarget.replaceChildren(fragment)
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
      this.previewContentTarget.replaceChildren()
    }
  }

  buildPlanPreview(plan) {
    const wrapper = document.createElement("div")
    wrapper.className = "mb-3"

    const name = document.createElement("strong")
    name.textContent = this.toText(plan.contest_name)
    wrapper.appendChild(name)
    wrapper.appendChild(
      document.createTextNode(` (${this.toText(plan.instance_label)}) — Round ${this.toText(plan.round_number)}`)
    )
    wrapper.appendChild(this.buildChangesTable(plan.changes))
    return wrapper
  }

  buildChangesTable(changes) {
    const table = document.createElement("table")
    table.className = "table table-sm table-bordered mt-2 mb-0"

    const thead = document.createElement("thead")
    const headerRow = document.createElement("tr")
    ;["Round", "Field", "Current", "Proposed", "Reason"].forEach((label) => {
      const th = document.createElement("th")
      th.textContent = label
      headerRow.appendChild(th)
    })
    thead.appendChild(headerRow)
    table.appendChild(thead)

    const tbody = document.createElement("tbody")
    ;(changes || []).forEach((change) => {
      const row = document.createElement("tr")
      this.appendTextCell(row, `Round ${this.toText(change.round_number)}`)
      this.appendTextCell(row, this.toText(change.field).replace("_", " "))
      this.appendTextCell(row, change.from)
      this.appendTextCell(row, change.to)
      this.appendTextCell(row, change.reason)
      tbody.appendChild(row)
    })
    table.appendChild(tbody)

    return table
  }

  appendTextCell(row, value) {
    const cell = document.createElement("td")
    cell.textContent = this.toText(value)
    row.appendChild(cell)
  }

  toText(value) {
    return value == null ? "" : String(value)
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

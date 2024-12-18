import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

export default class extends Controller {
  connect() {
    console.log("TooltipEmailDisplayController connected")
    this.initializeTooltips()
  }

  disconnect() {
    this.destroyTooltips()
  }

  initializeTooltips() {
    const tooltipTriggerList = this.element.querySelectorAll('[data-bs-toggle="tooltip"]')
    this.tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl =>
      new Tooltip(tooltipTriggerEl, {
        html: true
      })
    )
  }

  destroyTooltips() {
    if (this.tooltipList) {
      this.tooltipList.forEach(tooltip => tooltip.dispose())
    }
  }
}

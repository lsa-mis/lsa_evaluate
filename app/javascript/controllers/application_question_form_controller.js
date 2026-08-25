import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choices"]
  static values = {
    selectTypes: { type: Array, default: ["select", "select_with_other"] }
  }

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasChoicesTarget) return

    const fieldType = this.element.querySelector('[name="application_question[field_type]"]')?.value
    this.choicesTarget.classList.toggle("d-none", !this.selectTypesValue.includes(fieldType))
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choices", "requiresAcceptance"]
  static values = {
    selectTypes: { type: Array, default: ["select", "select_with_other"] },
    booleanType: { type: String, default: "boolean" }
  }

  connect() {
    this.toggle()
  }

  toggle() {
    const fieldType = this.element.querySelector('[name="application_question[field_type]"]')?.value

    if (this.hasChoicesTarget) {
      this.choicesTarget.classList.toggle("d-none", !this.selectTypesValue.includes(fieldType))
    }

    if (this.hasRequiresAcceptanceTarget) {
      this.requiresAcceptanceTarget.classList.toggle("d-none", fieldType !== this.booleanTypeValue)
    }
  }
}

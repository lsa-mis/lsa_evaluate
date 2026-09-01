import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choices", "requiresAcceptance", "defaultValue", "defaultValueField"]
  static values = {
    selectTypes: { type: Array, default: ["select", "select_with_other"] },
    booleanType: { type: String, default: "boolean" },
    defaultValueTypes: {
      type: Array,
      default: ["string", "text", "date", "select", "select_with_other", "boolean", "campus", "school"]
    }
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

    if (this.hasDefaultValueTarget) {
      const showDefault = this.defaultValueTypesValue.includes(fieldType)
      this.defaultValueTarget.classList.toggle("d-none", !showDefault)
    }

    this.defaultValueFieldTargets.forEach((element) => {
      const active = element.dataset.fieldType === fieldType
      element.classList.toggle("d-none", !active)
      element.querySelectorAll("input, select, textarea").forEach((input) => {
        input.disabled = !active
      })
    })
  }
}

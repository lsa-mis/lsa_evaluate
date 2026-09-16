import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "choices",
    "choicesHint",
    "choicesInput",
    "requiresAcceptance",
    "defaultValue",
    "defaultValueField",
    "multiselectDefaults"
  ]
  static values = {
    selectTypes: { type: Array, default: ["select", "select_with_other", "multiselect"] },
    booleanType: { type: String, default: "boolean" },
    defaultValueTypes: {
      type: Array,
      default: ["string", "text", "date", "select", "select_with_other", "multiselect", "boolean", "campus", "school"]
    }
  }

  connect() {
    this.toggle()
  }

  toggle() {
    const fieldType = this.fieldType()

    if (this.hasChoicesTarget) {
      this.choicesTarget.classList.toggle("d-none", !this.selectTypesValue.includes(fieldType))
    }

    this.choicesHintTargets.forEach((element) => {
      const multiple = element.dataset.selectKind === "multiple"
      element.classList.toggle("d-none", fieldType === "multiselect" ? !multiple : multiple)
    })

    if (this.hasRequiresAcceptanceTarget) {
      this.requiresAcceptanceTarget.classList.toggle("d-none", fieldType !== this.booleanTypeValue)
    }

    if (this.hasDefaultValueTarget) {
      const showDefault = this.defaultValueTypesValue.includes(fieldType)
      this.defaultValueTarget.classList.toggle("d-none", !showDefault)
    }

    this.syncChoiceDefaults()
    this.applyDefaultFieldEnabledState()
  }

  syncChoiceDefaults() {
    if (!this.hasMultiselectDefaultsTarget) return

    const choices = this.choiceList()
    const container = this.multiselectDefaultsTarget
    const checked = new Set(
      Array.from(container.querySelectorAll("input[type='checkbox']:checked")).map((input) => input.value)
    )
    const disabled = this.fieldType() !== "multiselect"

    container.replaceChildren(
      ...choices.map((choice, index) => this.buildDefaultCheckbox(choice, index, checked.has(choice), disabled))
    )
  }

  fieldType() {
    return this.element.querySelector('[name="application_question[field_type]"]')?.value
  }

  choiceList() {
    if (!this.hasChoicesInputTarget) return []

    return this.choicesInputTarget.value
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
  }

  buildDefaultCheckbox(choice, index, isChecked, disabled) {
    const wrapper = document.createElement("div")
    wrapper.className = "form-check"

    const id = `application_question_options_default_value_${index}`
    const input = document.createElement("input")
    input.type = "checkbox"
    input.className = "form-check-input"
    input.name = "application_question[options][default_value][]"
    input.value = choice
    input.id = id
    input.checked = isChecked
    input.disabled = disabled

    const label = document.createElement("label")
    label.className = "form-check-label"
    label.htmlFor = id
    label.textContent = choice

    wrapper.append(input, label)
    return wrapper
  }

  applyDefaultFieldEnabledState() {
    const fieldType = this.fieldType()

    this.defaultValueFieldTargets.forEach((element) => {
      const active = element.dataset.fieldType === fieldType
      element.classList.toggle("d-none", !active)
      element.querySelectorAll("input, select, textarea").forEach((input) => {
        input.disabled = !active
      })
    })
  }
}

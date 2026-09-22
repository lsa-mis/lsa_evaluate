import { Controller } from "@hotwired/stimulus"

// Toggles class-level-scoped application questions and defaults School to Rackham for graduates.
export default class extends Controller {
  static targets = ["classLevel", "question", "requiredMarker", "schoolSelect", "schoolRackhamHint"]
  static values = {
    graduateClassLevelIds: { type: Array, default: [] },
    rackhamSchoolId: { type: Number, default: 0 }
  }

  connect() {
    this.refresh()
  }

  refresh() {
    const graduate = this.isGraduate()

    this.questionTargets.forEach((wrapper) => {
      const scope = wrapper.dataset.classLevelScope || "all"
      const applicable =
        scope === "all" ||
        (scope === "graduate" && graduate) ||
        (scope === "undergraduate" && !graduate)
      const requiredWhenApplicable = wrapper.dataset.requiredWhenApplicable === "true"

      wrapper.classList.toggle("d-none", !applicable)
      this.setInputsDisabled(wrapper, !applicable)
      this.setInputsRequired(wrapper, applicable && requiredWhenApplicable)
      this.updateRequiredMarker(wrapper, applicable && requiredWhenApplicable)
    })

    if (graduate) {
      this.defaultSchoolToRackham()
    }

    this.updateSchoolRackhamHint(graduate)
  }

  isGraduate() {
    if (!this.hasClassLevelTarget) return false

    const selectedId = String(this.classLevelTarget.value || "")
    return this.graduateClassLevelIdsValue.map(String).includes(selectedId)
  }

  setInputsDisabled(wrapper, disabled) {
    wrapper.querySelectorAll("input, select, textarea").forEach((input) => {
      input.disabled = disabled
    })
  }

  setInputsRequired(wrapper, required) {
    wrapper.querySelectorAll("input, select, textarea").forEach((input) => {
      // Agreement checkboxes and "other" text fields manage requiredness separately / optionally.
      if (input.type === "checkbox") return
      if (input.id && input.id.endsWith("_other")) {
        input.required = false
        return
      }

      input.required = required
    })
  }

  updateRequiredMarker(wrapper, showMarker) {
    const marker = wrapper.querySelector('[data-class-level-questions-target="requiredMarker"]')
    if (!marker) return

    marker.classList.toggle("d-none", !showMarker)
  }

  defaultSchoolToRackham() {
    if (!this.hasSchoolSelectTarget) return
    if (!this.rackhamSchoolIdValue) return
    if (this.schoolSelectTarget.value) return

    this.schoolSelectTarget.value = String(this.rackhamSchoolIdValue)
  }

  updateSchoolRackhamHint(graduate = this.isGraduate()) {
    if (!this.hasSchoolRackhamHintTarget) return

    const schoolValue = this.hasSchoolSelectTarget ? String(this.schoolSelectTarget.value || "") : ""
    const rackhamId = String(this.rackhamSchoolIdValue || "")
    const showHint = graduate && schoolValue !== "" && schoolValue !== rackhamId

    this.schoolRackhamHintTarget.classList.toggle("d-none", !showHint)
  }
}

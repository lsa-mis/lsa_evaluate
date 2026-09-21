import { Application } from "@hotwired/stimulus"
import ApplicationQuestionFormController from "../../../app/javascript/controllers/application_question_form_controller"

describe("ApplicationQuestionFormController", () => {
  let application
  let container

  const formHtml = `
    <form data-controller="application-question-form"
          data-action="change->application-question-form#toggle">
      <select name="application_question[field_type]">
        <option value="string" selected>Short answer (one line)</option>
        <option value="text">Paragraph</option>
        <option value="select">Dropdown (choose one)</option>
        <option value="select_with_other">Dropdown with Other</option>
        <option value="multiselect">Checkboxes (choose one or more)</option>
      </select>
      <div data-application-question-form-target="choices">
        <textarea name="application_question[options][choices]"
                  data-application-question-form-target="choicesInput"
                  data-action="input->application-question-form#syncChoiceDefaults"></textarea>
      </div>
      <div data-application-question-form-target="defaultValueField multiselectDefaults"
           data-field-type="multiselect"></div>
    </form>
  `

  beforeEach(() => {
    container = document.createElement("div")
    container.innerHTML = formHtml
    document.body.appendChild(container)

    application = Application.start()
    application.register("application-question-form", ApplicationQuestionFormController)
  })

  afterEach(() => {
    document.body.removeChild(container)
    application.stop()
  })

  const fieldTypeSelect = () => container.querySelector('[name="application_question[field_type]"]')
  const choices = () => container.querySelector('[data-application-question-form-target="choices"]')
  const choicesInput = () => container.querySelector('[data-application-question-form-target="choicesInput"]')
  const defaultCheckboxes = () => container.querySelectorAll('[data-field-type="multiselect"] input[type="checkbox"]')

  it("hides dropdown choices for a short answer on connect", () => {
    expect(choices().classList.contains("d-none")).toBe(true)
  })

  it("shows dropdown choices when the answer type is a dropdown", () => {
    fieldTypeSelect().value = "select"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))

    expect(choices().classList.contains("d-none")).toBe(false)
  })

  it("shows dropdown choices when the answer type includes Other", () => {
    fieldTypeSelect().value = "select_with_other"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))

    expect(choices().classList.contains("d-none")).toBe(false)
  })

  it("shows choices when the answer type is checkboxes", () => {
    fieldTypeSelect().value = "multiselect"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))

    expect(choices().classList.contains("d-none")).toBe(false)
  })

  it("hides dropdown choices again after switching back to a short answer", () => {
    fieldTypeSelect().value = "select"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))
    fieldTypeSelect().value = "string"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))

    expect(choices().classList.contains("d-none")).toBe(true)
  })

  it("builds default checkboxes from the choices textarea while creating a question", () => {
    fieldTypeSelect().value = "multiselect"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))
    choicesInput().value = "Poetry\nFiction\n Drama "
    choicesInput().dispatchEvent(new Event("input", { bubbles: true }))

    const boxes = defaultCheckboxes()
    expect(boxes).toHaveLength(3)
    expect(Array.from(boxes).map((input) => input.value)).toEqual(["Poetry", "Fiction", "Drama"])
    expect(Array.from(boxes).every((input) => !input.disabled)).toBe(true)
  })

  it("keeps checked default checkboxes when the choice list is edited", () => {
    fieldTypeSelect().value = "multiselect"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))
    choicesInput().value = "Poetry\nFiction"
    choicesInput().dispatchEvent(new Event("input", { bubbles: true }))
    defaultCheckboxes()[0].checked = true

    choicesInput().value = "Poetry\nDrama"
    choicesInput().dispatchEvent(new Event("input", { bubbles: true }))

    const boxes = defaultCheckboxes()
    expect(Array.from(boxes).map((input) => input.value)).toEqual(["Poetry", "Drama"])
    expect(boxes[0].checked).toBe(true)
    expect(boxes[1].checked).toBe(false)
  })
})

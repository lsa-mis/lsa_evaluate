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
      </select>
      <div data-application-question-form-target="choices">Dropdown choices</div>
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

  it("hides dropdown choices again after switching back to a short answer", () => {
    fieldTypeSelect().value = "select"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))
    fieldTypeSelect().value = "string"
    fieldTypeSelect().dispatchEvent(new Event("change", { bubbles: true }))

    expect(choices().classList.contains("d-none")).toBe(true)
  })
})

import { Application } from "@hotwired/stimulus"
import ClassLevelQuestionsController from "../../../app/javascript/controllers/class_level_questions_controller"

describe("ClassLevelQuestionsController", () => {
  let application
  let container

  const formHtml = `
    <form data-controller="class-level-questions"
          data-class-level-questions-graduate-class-level-ids-value='[2]'
          data-class-level-questions-rackham-school-id-value="99">
      <select data-class-level-questions-target="classLevel"
              data-action="change->class-level-questions#refresh">
        <option value="1" selected>First year</option>
        <option value="2">Graduate</option>
      </select>
      <div data-class-level-questions-target="question"
           data-class-level-scope="undergraduate"
           data-required-when-applicable="true">
        <span data-class-level-questions-target="requiredMarker">*</span>
        <input type="text" name="major" />
      </div>
      <div data-class-level-questions-target="question"
           data-class-level-scope="graduate"
           data-required-when-applicable="true"
           class="d-none">
        <span data-class-level-questions-target="requiredMarker" class="d-none">*</span>
        <select name="department"><option value=""></option><option value="Law">Law</option></select>
      </div>
      <div data-class-level-questions-target="question" data-class-level-scope="all" data-required-when-applicable="true">
        <select data-class-level-questions-target="schoolSelect"
                data-action="change->class-level-questions#refresh"
                name="school">
          <option value=""></option>
          <option value="99">Rackham</option>
          <option value="5" selected>LSA</option>
        </select>
        <div class="d-none" data-class-level-questions-target="schoolRackhamHint">
          Consider Rackham
        </div>
      </div>
    </form>
  `

  beforeEach(() => {
    container = document.createElement("div")
    container.innerHTML = formHtml
    document.body.appendChild(container)

    application = Application.start()
    application.register("class-level-questions", ClassLevelQuestionsController)
  })

  afterEach(() => {
    document.body.removeChild(container)
    application.stop()
  })

  function form() {
    return container.querySelector("form")
  }

  it("hides graduate questions for undergraduates and shows major", () => {
    const major = form().querySelector('[data-class-level-scope="undergraduate"]')
    const department = form().querySelector('[data-class-level-scope="graduate"]')
    const hint = form().querySelector('[data-class-level-questions-target="schoolRackhamHint"]')

    expect(major.classList.contains("d-none")).toBe(false)
    expect(department.classList.contains("d-none")).toBe(true)
    expect(department.querySelector("select").disabled).toBe(true)
    expect(hint.classList.contains("d-none")).toBe(true)
  })

  it("shows graduate questions and defaults school to Rackham when Graduate is selected and school is blank", () => {
    const school = form().querySelector('[data-class-level-questions-target="schoolSelect"]')
    school.value = ""

    const select = form().querySelector('[data-class-level-questions-target="classLevel"]')
    select.value = "2"
    select.dispatchEvent(new Event("change"))

    const major = form().querySelector('[data-class-level-scope="undergraduate"]')
    const department = form().querySelector('[data-class-level-scope="graduate"]')

    expect(major.classList.contains("d-none")).toBe(true)
    expect(department.classList.contains("d-none")).toBe(false)
    expect(department.querySelector("select").disabled).toBe(false)
    expect(school.value).toBe("99")
  })

  it("keeps a prior school and shows the Rackham reminder for graduates", () => {
    const school = form().querySelector('[data-class-level-questions-target="schoolSelect"]')
    const hint = form().querySelector('[data-class-level-questions-target="schoolRackhamHint"]')
    expect(school.value).toBe("5")

    const select = form().querySelector('[data-class-level-questions-target="classLevel"]')
    select.value = "2"
    select.dispatchEvent(new Event("change"))

    expect(school.value).toBe("5")
    expect(hint.classList.contains("d-none")).toBe(false)

    school.value = "99"
    school.dispatchEvent(new Event("change"))
    expect(hint.classList.contains("d-none")).toBe(true)
  })
})

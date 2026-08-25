import { Application } from "@hotwired/stimulus"
import ApplicationQuestionSortController from "../../../app/javascript/controllers/application_question_sort_controller"

describe("ApplicationQuestionSortController", () => {
  let application
  let container
  let createdOptions
  let mockSortable

  beforeEach(() => {
    createdOptions = null
    mockSortable = { destroy: jest.fn() }
    global.Sortable = {
      create: jest.fn((_element, options) => {
        createdOptions = options
        return mockSortable
      })
    }

    document.head.innerHTML = '<meta name="csrf-token" content="test-token">'
    container = document.createElement("div")
    container.innerHTML = `
      <table>
        <tbody data-controller="application-question-sort"
               data-application-question-sort-url-value="/containers/1/application_questions/reorder">
          <tr data-question-id="10"><td class="drag-handle">A</td></tr>
          <tr data-question-id="20"><td class="drag-handle">B</td></tr>
          <tr data-question-id="30"><td class="drag-handle">C</td></tr>
        </tbody>
      </table>
    `
    document.body.appendChild(container)

    application = Application.start()
    application.register("application-question-sort", ApplicationQuestionSortController)
  })

  afterEach(() => {
    document.body.removeChild(container)
    application.stop()
    global.fetch.mockClear()
    delete global.Sortable
  })

  it("initializes Sortable with a drag handle", () => {
    expect(global.Sortable.create).toHaveBeenCalled()
    expect(createdOptions.handle).toBe(".drag-handle")
  })

  it("posts the row order when a drag ends", async () => {
    await createdOptions.onEnd()

    expect(global.fetch).toHaveBeenCalledWith(
      "/containers/1/application_questions/reorder",
      expect.objectContaining({
        method: "PATCH",
        headers: expect.objectContaining({
          "X-CSRF-Token": "test-token",
          "Content-Type": "application/json"
        }),
        body: JSON.stringify({ application_question_ids: ["10", "20", "30"] })
      })
    )
  })

  it("reloads the page when saving the order fails", async () => {
    const reloadSpy = jest.spyOn(ApplicationQuestionSortController.prototype, "reload").mockImplementation(() => {})
    global.fetch.mockResolvedValueOnce({ ok: false })

    await createdOptions.onEnd()

    expect(reloadSpy).toHaveBeenCalled()
    reloadSpy.mockRestore()
  })
})

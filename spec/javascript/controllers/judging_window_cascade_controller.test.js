import { Application } from "@hotwired/stimulus"
import JudgingWindowCascadeController from "../../../app/javascript/controllers/judging_window_cascade_controller"

describe("JudgingWindowCascadeController", () => {
  let application
  let container
  let controller

  const xssPayload = '<img src=x onerror="window.__xssRan = true">'

  const conflictingPlan = (overrides = {}) => ({
    contest_name: "Poetry",
    instance_label: "Jan 1 – Jan 31",
    round_number: 1,
    conflicts: true,
    changes: [
      {
        round_number: 2,
        field: "start_date",
        from: "February 01, 2026 12:00 AM",
        to: "February 02, 2026 12:00 AM",
        reason: "Must be on or after Round 1 end date"
      }
    ],
    ...overrides
  })

  beforeEach(async () => {
    window.__xssRan = false
    container = document.createElement("div")
    container.innerHTML = `
      <form data-controller="judging-window-cascade">
        <input type="datetime-local" data-judging-window-cascade-target="endDate">
        <div data-judging-window-cascade-target="previewPanel" class="d-none">
          <div data-judging-window-cascade-target="previewContent"></div>
        </div>
        <input type="checkbox" data-judging-window-cascade-target="cascadeToggle">
      </form>
    `
    document.body.appendChild(container)

    application = Application.start()
    application.register("judging-window-cascade", JudgingWindowCascadeController)
    await new Promise((resolve) => setTimeout(resolve, 0))

    controller = application.getControllerForElementAndIdentifier(
      container.querySelector("[data-controller='judging-window-cascade']"),
      "judging-window-cascade"
    )
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
    delete window.__xssRan
  })

  describe("renderPreview", () => {
    it("renders contest names and change details as text, not HTML", () => {
      controller.renderPreview([
        conflictingPlan({
          contest_name: xssPayload,
          instance_label: `<svg onload="window.__xssRan = true">`,
          changes: [
            {
              round_number: 2,
              field: "start_date",
              from: "<b>from</b>",
              to: "<i>to</i>",
              reason: `<img src=x onerror="window.__xssRan = true">`
            }
          ]
        })
      ])

      const preview = controller.previewContentTarget
      expect(preview.querySelector("img")).toBeNull()
      expect(preview.querySelector("svg")).toBeNull()
      expect(preview.querySelector("b")).toBeNull()
      expect(preview.querySelector("i")).toBeNull()
      expect(preview.querySelector("strong").textContent).toBe(xssPayload)
      expect(preview.textContent).toContain("<svg onload=")
      expect(preview.textContent).toContain("<b>from</b>")
      expect(preview.textContent).toContain("<i>to</i>")
      expect(preview.textContent).toContain(xssPayload)
      expect(window.__xssRan).toBe(false)
    })

    it("shows the preview panel and checks cascade when conflicts exist", () => {
      controller.renderPreview([conflictingPlan()])

      expect(controller.previewPanelTarget.classList.contains("d-none")).toBe(false)
      expect(controller.cascadeToggleTarget.checked).toBe(true)
      expect(controller.previewContentTarget.querySelector("table")).not.toBeNull()
      expect(controller.previewContentTarget.textContent).toContain("Poetry")
    })

    it("hides the preview when there are no conflicts", () => {
      controller.renderPreview([conflictingPlan({ conflicts: false })])

      expect(controller.previewPanelTarget.classList.contains("d-none")).toBe(true)
      expect(controller.previewContentTarget.childNodes.length).toBe(0)
    })
  })

  describe("renderSingleRoundPreview", () => {
    it("renders change fields as text, not HTML", () => {
      controller.renderSingleRoundPreview({
        conflicts: true,
        changes: [
          {
            round_number: 2,
            field: "end_date",
            from: `<img src=x onerror="window.__xssRan = true">`,
            to: "<script>window.__xssRan = true</script>",
            reason: xssPayload
          }
        ]
      })

      const preview = controller.previewContentTarget
      expect(preview.querySelector("img")).toBeNull()
      expect(preview.querySelector("script")).toBeNull()
      expect(preview.textContent).toContain(xssPayload)
      expect(preview.textContent).toContain("<script>window.__xssRan = true</script>")
      expect(window.__xssRan).toBe(false)
    })
  })
})

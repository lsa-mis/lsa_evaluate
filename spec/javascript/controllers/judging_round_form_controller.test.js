import { Application } from "@hotwired/stimulus"
import JudgingRoundFormController from "../../../app/javascript/controllers/judging_round_form_controller"

describe("JudgingRoundFormController", () => {
  let application
  let container

  beforeEach(() => {
    container = document.createElement("div")
    container.innerHTML = `
      <form data-controller="judging-round-form" data-judging-round-form-target="form">
        <input type="datetime-local" name="judging_round[start_date]">
        <button type="submit">Update Round</button>
      </form>
    `
    document.body.appendChild(container)

    application = Application.start()
    application.register("judging-round-form", JudgingRoundFormController)

    // Mock Bootstrap as undefined by default
    delete global.bootstrap
  })

  afterEach(() => {
    document.body.removeChild(container)
  })

  describe("when submitting the form", () => {
    it("shows confirmation dialog for past dates", async () => {
      // Set a past date
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 1)
      const input = container.querySelector('input[name="judging_round[start_date]"]')
      input.value = pastDate.toISOString().slice(0, 16)

      // Mock window.confirm since we're falling back to it when Bootstrap is not available
      const originalConfirm = window.confirm
      let confirmCalled = false
      window.confirm = () => {
        confirmCalled = true
        return false // Return false to simulate canceling
      }

      try {
        // Submit the form
        const form = container.querySelector('form')
        const submitEvent = new Event('submit', { cancelable: true }) // Make the event cancelable
        form.dispatchEvent(submitEvent)

        // Wait for any promises to resolve
        await new Promise(resolve => setTimeout(resolve, 0))

        // Verify confirmation was shown and form submission was prevented
        expect(confirmCalled).toBe(true)
        expect(submitEvent.defaultPrevented).toBe(true)
      } finally {
        // Restore original confirm
        window.confirm = originalConfirm
      }
    })

    it("submits directly for future dates", () => {
      // Set a future date
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 1)
      const input = container.querySelector('input[name="judging_round[start_date]"]')
      input.value = futureDate.toISOString().slice(0, 16)

      // Submit the form
      const form = container.querySelector('form')
      const submitEvent = new Event('submit', { cancelable: true })
      form.dispatchEvent(submitEvent)

      // Verify form was submitted without confirmation
      expect(submitEvent.defaultPrevented).toBe(false)
    })

    it("submits when already confirmed", () => {
      // Set a past date
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 1)
      const input = container.querySelector('input[name="judging_round[start_date]"]')
      input.value = pastDate.toISOString().slice(0, 16)

      // Add confirmed input
      const confirmedInput = document.createElement('input')
      confirmedInput.type = 'hidden'
      confirmedInput.name = 'confirmed'
      confirmedInput.value = 'true'
      container.querySelector('form').appendChild(confirmedInput)

      // Submit the form
      const form = container.querySelector('form')
      const submitEvent = new Event('submit', { cancelable: true })
      form.dispatchEvent(submitEvent)

      // Verify form was submitted without confirmation
      expect(submitEvent.defaultPrevented).toBe(false)
    })
  })

  describe("when Bootstrap is available", () => {
    beforeEach(() => {
      // Mock Bootstrap Modal
      global.bootstrap = {
        Modal: jest.fn().mockImplementation(() => ({
          show: jest.fn(),
          hide: jest.fn(),
          element: document.createElement('div')
        }))
      }
    })

    afterEach(() => {
      delete global.bootstrap
    })

    it("uses Bootstrap modal for confirmation", async () => {
      // Set a past date
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 1)
      const input = container.querySelector('input[name="judging_round[start_date]"]')
      input.value = pastDate.toISOString().slice(0, 16)

      // Submit the form
      const form = container.querySelector('form')
      const submitEvent = new Event('submit', { cancelable: true })
      form.dispatchEvent(submitEvent)

      // Verify Bootstrap Modal was used
      expect(bootstrap.Modal).toHaveBeenCalled()
    })
  })
})

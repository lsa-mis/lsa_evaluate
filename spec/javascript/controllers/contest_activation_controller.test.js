import { Application } from "@hotwired/stimulus"
import ContestActivationController from "../../../app/javascript/controllers/contest_activation_controller"

describe("ContestActivationController", () => {
  let application
  let container

  beforeEach(() => {
    container = document.createElement("div")
    document.body.appendChild(container)

    application = Application.start()
    application.register("contest-activation", ContestActivationController)
  })

  afterEach(() => {
    document.body.removeChild(container)
    application.stop()
  })

  describe("when creating a new record", () => {
    beforeEach(() => {
      container.innerHTML = `
        <form data-controller="contest-activation"
              data-contest-activation-is-new-record-value="true">
          <input type="checkbox"
                 data-contest-activation-target="activeCheckbox"
                 name="contest_description[active]">
          <button type="submit"
                  data-contest-activation-target="submitButton">Create Contest</button>
        </form>
      `
    })

    describe("when active checkbox is checked", () => {
      it("submits form normally without confirmation", () => {
        const checkbox = container.querySelector('[data-contest-activation-target="activeCheckbox"]')
        const submitButton = container.querySelector('[data-contest-activation-target="submitButton"]')
        const form = container.querySelector('form')

        checkbox.checked = true

        // Mock form submission
        let formSubmitted = false
        form.addEventListener('submit', (e) => {
          e.preventDefault()
          formSubmitted = true
        })

        // Click submit button
        const clickEvent = new Event('click', { cancelable: true })
        submitButton.dispatchEvent(clickEvent)

        expect(clickEvent.defaultPrevented).toBe(false)
        expect(formSubmitted).toBe(true)
      })
    })

    describe("when active checkbox is not checked", () => {
      it("shows confirmation dialog and activates if user confirms", () => {
        const checkbox = container.querySelector('[data-contest-activation-target="activeCheckbox"]')
        const submitButton = container.querySelector('[data-contest-activation-target="submitButton"]')
        const form = container.querySelector('form')

        checkbox.checked = false

        // Mock window.confirm to return true (user confirms)
        const originalConfirm = window.confirm
        let confirmMessage = ''
        window.confirm = (message) => {
          confirmMessage = message
          return true
        }

        // Mock form submission
        let formSubmitted = false
        form.addEventListener('submit', (e) => {
          e.preventDefault()
          formSubmitted = true
        })

        try {
          // Click submit button
          const clickEvent = new Event('click', { cancelable: true })
          submitButton.dispatchEvent(clickEvent)

          // Check that confirmation was shown
          expect(confirmMessage).toContain('This contest will be created as inactive')
          expect(confirmMessage).toContain('Would you like to make it active now?')

          // Check that checkbox was checked after confirmation
          expect(checkbox.checked).toBe(true)

          // Form should be submitted
          expect(formSubmitted).toBe(true)
        } finally {
          window.confirm = originalConfirm
        }
      })

      it("keeps checkbox unchecked if user cancels", () => {
        const checkbox = container.querySelector('[data-contest-activation-target="activeCheckbox"]')
        const submitButton = container.querySelector('[data-contest-activation-target="submitButton"]')
        const form = container.querySelector('form')

        checkbox.checked = false

        // Mock window.confirm to return false (user cancels)
        const originalConfirm = window.confirm
        window.confirm = () => false

        // Mock form submission
        let formSubmitted = false
        form.addEventListener('submit', (e) => {
          e.preventDefault()
          formSubmitted = true
        })

        try {
          // Click submit button
          const clickEvent = new Event('click', { cancelable: true })
          submitButton.dispatchEvent(clickEvent)

          // Check that checkbox remains unchecked
          expect(checkbox.checked).toBe(false)

          // Form should still be submitted
          expect(formSubmitted).toBe(true)
        } finally {
          window.confirm = originalConfirm
        }
      })

      it("uses custom confirmation message when provided", () => {
        container.innerHTML = `
          <form data-controller="contest-activation"
                data-contest-activation-is-new-record-value="true"
                data-contest-activation-confirm-message-value="Custom message for testing">
            <input type="checkbox"
                   data-contest-activation-target="activeCheckbox"
                   name="contest_description[active]">
            <button type="submit"
                    data-contest-activation-target="submitButton">Create Contest</button>
          </form>
        `

        const checkbox = container.querySelector('[data-contest-activation-target="activeCheckbox"]')
        const submitButton = container.querySelector('[data-contest-activation-target="submitButton"]')

        checkbox.checked = false

        // Mock window.confirm
        const originalConfirm = window.confirm
        let confirmMessage = ''
        window.confirm = (message) => {
          confirmMessage = message
          return true
        }

        try {
          // Click submit button
          const clickEvent = new Event('click', { cancelable: true })
          submitButton.dispatchEvent(clickEvent)

          expect(confirmMessage).toBe('Custom message for testing')
        } finally {
          window.confirm = originalConfirm
        }
      })
    })
  })

  describe("when editing an existing record", () => {
    beforeEach(() => {
      container.innerHTML = `
        <form data-controller="contest-activation"
              data-contest-activation-is-new-record-value="false">
          <input type="checkbox"
                 data-contest-activation-target="activeCheckbox"
                 name="contest_description[active]">
          <button type="submit"
                  data-contest-activation-target="submitButton">Update Contest</button>
        </form>
      `
    })

    it("submits form normally without any confirmation", () => {
      const checkbox = container.querySelector('[data-contest-activation-target="activeCheckbox"]')
      const submitButton = container.querySelector('[data-contest-activation-target="submitButton"]')
      const form = container.querySelector('form')

      checkbox.checked = false // Even when unchecked

      // Mock form submission
      let formSubmitted = false
      form.addEventListener('submit', (e) => {
        e.preventDefault()
        formSubmitted = true
      })

      // Mock window.confirm (should not be called)
      const originalConfirm = window.confirm
      let confirmCalled = false
      window.confirm = () => {
        confirmCalled = true
        return true
      }

      try {
        // Click submit button
        const clickEvent = new Event('click', { cancelable: true })
        submitButton.dispatchEvent(clickEvent)

        expect(confirmCalled).toBe(false)
        expect(formSubmitted).toBe(true)
        expect(clickEvent.defaultPrevented).toBe(false)
      } finally {
        window.confirm = originalConfirm
      }
    })
  })

  describe("controller connection", () => {
    it("logs connection message", () => {
      const originalLog = console.log
      let logMessage = ''
      console.log = (message) => {
        logMessage = message
      }

      try {
        container.innerHTML = `
          <form data-controller="contest-activation"
                data-contest-activation-is-new-record-value="true">
            <input type="checkbox" data-contest-activation-target="activeCheckbox">
            <button type="submit" data-contest-activation-target="submitButton">Submit</button>
          </form>
        `

        expect(logMessage).toBe('contest-activation controller connected')
      } finally {
        console.log = originalLog
      }
    })
  })
})

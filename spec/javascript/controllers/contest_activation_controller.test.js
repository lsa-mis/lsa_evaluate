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

        // Mock form submission - listen for submit event
        let formSubmitted = false
        form.addEventListener('submit', (e) => {
          e.preventDefault()
          formSubmitted = true
        })

        // Mock requestSubmit if it doesn't exist
        if (!form.requestSubmit) {
          form.requestSubmit = function() {
            const submitEvent = new Event('submit', { cancelable: true, bubbles: true })
            this.dispatchEvent(submitEvent)
          }
        }

        // Click submit button - this will trigger the controller's event listener
        submitButton.click()

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

        // Mock requestSubmit if it doesn't exist
        if (!form.requestSubmit) {
          form.requestSubmit = function() {
            const submitEvent = new Event('submit', { cancelable: true, bubbles: true })
            this.dispatchEvent(submitEvent)
          }
        }

        try {
          // Click submit button
          submitButton.click()

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

        // Mock requestSubmit if it doesn't exist
        if (!form.requestSubmit) {
          form.requestSubmit = function() {
            const submitEvent = new Event('submit', { cancelable: true, bubbles: true })
            this.dispatchEvent(submitEvent)
          }
        }

        try {
          // Click submit button
          submitButton.click()

          // Check that checkbox remains unchecked
          expect(checkbox.checked).toBe(false)

          // Form should still be submitted
          expect(formSubmitted).toBe(true)
        } finally {
          window.confirm = originalConfirm
        }
      })

      it("uses custom confirmation message when provided", (done) => {
        // Mock window.confirm FIRST
        const originalConfirm = window.confirm
        let confirmMessage = ''
        window.confirm = (message) => {
          confirmMessage = message
          return true
        }

        // Mock HTMLFormElement.prototype.requestSubmit globally for JSDOM
        const originalRequestSubmit = HTMLFormElement.prototype.requestSubmit
        HTMLFormElement.prototype.requestSubmit = function(submitter) {
          const submitEvent = new Event('submit', { cancelable: true, bubbles: true })
          // Set the submitter property on the event
          Object.defineProperty(submitEvent, 'submitter', {
            value: submitter,
            writable: false
          })
          this.dispatchEvent(submitEvent)
        }

        try {
          // Create container and add HTML with custom confirmation message
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

          // Wait for Stimulus to connect the controller
          setTimeout(() => {
            const checkbox = container.querySelector('[data-contest-activation-target="activeCheckbox"]')
            const submitButton = container.querySelector('[data-contest-activation-target="submitButton"]')
            const form = container.querySelector('form')

            checkbox.checked = false

            // Mock form submission
            let formSubmitted = false
            form.addEventListener('submit', (e) => {
              e.preventDefault()
              formSubmitted = true
            })

            // Click the submit button
            submitButton.click()

            // Verify the custom confirmation message was shown
            expect(confirmMessage).toBe('Custom message for testing')

            // Check that checkbox was checked after confirmation
            expect(checkbox.checked).toBe(true)

            // Form should be submitted
            expect(formSubmitted).toBe(true)

            done()
          }, 50) // Give Stimulus time to initialize
        } catch (error) {
          // Restore original methods in case of error
          window.confirm = originalConfirm
          if (originalRequestSubmit) {
            HTMLFormElement.prototype.requestSubmit = originalRequestSubmit
          } else {
            delete HTMLFormElement.prototype.requestSubmit
          }
          done(error)
        } finally {
          // Clean up will happen after the test completes
          setTimeout(() => {
            window.confirm = originalConfirm
            if (originalRequestSubmit) {
              HTMLFormElement.prototype.requestSubmit = originalRequestSubmit
            } else {
              delete HTMLFormElement.prototype.requestSubmit
            }
          }, 100)
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
        // Click submit button - since isNewRecord is false,
        // the controller won't interfere and normal form submission should occur
        submitButton.click()

        expect(confirmCalled).toBe(false)
        expect(formSubmitted).toBe(true)
      } finally {
        window.confirm = originalConfirm
      }
    })
  })

  describe("controller connection", () => {
    it("logs connection message", (done) => {
      // Save original console.log
      const originalLog = console.log
      const capturedLogs = []

      // Mock console.log BEFORE creating any controller
      console.log = (...args) => {
        capturedLogs.push(args.join(' '))
        originalLog(...args) // Also call original to help debug
      }

      try {
        // Create a new container with the controller
        const testContainer = document.createElement('div')
        testContainer.innerHTML = `
          <div data-controller="contest-activation"
               data-contest-activation-is-new-record-value="true">
            <input type="checkbox" data-contest-activation-target="activeCheckbox">
            <button type="submit" data-contest-activation-target="submitButton">Submit</button>
          </div>
        `

        // Add to DOM - this will trigger Stimulus to instantiate the controller
        // and call its connect() method
        document.body.appendChild(testContainer)

        // Wait a bit for Stimulus to process
        setTimeout(() => {
          // The connection should have been logged
          const hasConnectionLog = capturedLogs.some(log => log.includes('contest-activation controller connected'))
          expect(hasConnectionLog).toBe(true)

          // Cleanup
          document.body.removeChild(testContainer)
          console.log = originalLog
          done()
        }, 50)
      } catch (error) {
        console.log = originalLog
        done(error)
      }
    })
  })
})

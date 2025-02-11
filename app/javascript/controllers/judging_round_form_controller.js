import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.formTarget.addEventListener("submit", this.handleSubmit.bind(this))
  }

  async handleSubmit(event) {
    if (this.needsConfirmation && !event.target.querySelector('input[name="confirmed"]')) {
      event.preventDefault()

      const confirmed = await this.showConfirmationDialog()
      if (confirmed) {
        const confirmedInput = document.createElement("input")
        confirmedInput.type = "hidden"
        confirmedInput.name = "confirmed"
        confirmedInput.value = "true"
        this.formTarget.appendChild(confirmedInput)
        this.formTarget.submit()
      }
    }
  }

  showConfirmationDialog() {
    return new Promise((resolve) => {
      if (typeof bootstrap === 'undefined') {
        return resolve(window.confirm("This round has already started. Changes may affect ongoing judging. Are you sure you want to proceed?"))
      }

      const modalElement = document.createElement("div")
      modalElement.className = "modal fade"
      modalElement.setAttribute("tabindex", "-1")
      modalElement.innerHTML = `
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Confirm Changes</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <div class="alert alert-warning">
                <i class="bi bi-exclamation-triangle-fill me-2"></i>
                <strong>Warning:</strong> This round has already started. Changes may affect ongoing judging.
              </div>
              <p>Are you sure you want to proceed with these changes?</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-primary confirm-button">Confirm Changes</button>
            </div>
          </div>
        </div>
      `

      document.body.appendChild(modalElement)
      const modal = new bootstrap.Modal(modalElement)

      modalElement.querySelector(".confirm-button").addEventListener("click", () => {
        modal.hide()
        resolve(true)
      })

      modalElement.addEventListener("hidden.bs.modal", () => {
        document.body.removeChild(modalElement)
        resolve(false)
      })

      modal.show()
    })
  }

  get needsConfirmation() {
    const startDateInput = this.formTarget.querySelector("[name*='[start_date]']")
    if (!startDateInput?.value) return false

    const startDate = new Date(startDateInput.value)
    const now = new Date()
    return startDate <= now
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    warningAfterMs: { type: Number, default: 110 * 60 * 1000 },
    heartbeatUrl: { type: String, default: "/session/heartbeat" }
  }

  connect() {
    this.lastActivityAt = Date.now()
    this.warningShown = false
    this.bindActivityListeners()
    this.startMonitoring()
  }

  disconnect() {
    clearInterval(this.monitorInterval)
    this.unbindActivityListeners()
  }

  bindActivityListeners() {
    this.activityHandler = () => {
      this.lastActivityAt = Date.now()
      if (this.warningShown) {
        this.hideWarning()
      }
    }

    ["click", "keydown", "mousemove", "scroll", "touchstart"].forEach((eventName) => {
      window.addEventListener(eventName, this.activityHandler, { passive: true })
    })
  }

  unbindActivityListeners() {
    if (!this.activityHandler) return

    ["click", "keydown", "mousemove", "scroll", "touchstart"].forEach((eventName) => {
      window.removeEventListener(eventName, this.activityHandler)
    })
  }

  startMonitoring() {
    this.monitorInterval = setInterval(() => this.checkIdleTime(), 30000)
  }

  checkIdleTime() {
    const idleFor = Date.now() - this.lastActivityAt
    if (idleFor >= this.warningAfterMsValue && !this.warningShown) {
      this.showWarning()
    }
  }

  showWarning() {
    this.warningShown = true
    const existing = document.getElementById("session-warning-modal")
    if (existing) return

    const modalElement = document.createElement("div")
    modalElement.id = "session-warning-modal"
    modalElement.className = "modal fade"
    modalElement.setAttribute("tabindex", "-1")
    modalElement.innerHTML = `
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Session expiring soon</h5>
          </div>
          <div class="modal-body">
            <p>Your session will expire soon due to inactivity. Click below to stay signed in and keep your work saved.</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-primary" data-action="session-warning#extendSession">Stay signed in</button>
          </div>
        </div>
      </div>
    `

    modalElement.querySelector("[data-action='session-warning#extendSession']")
      .addEventListener("click", () => this.extendSession())

    document.body.appendChild(modalElement)

    if (typeof bootstrap !== "undefined") {
      this.modal = new bootstrap.Modal(modalElement, { backdrop: "static", keyboard: false })
      this.modal.show()
    } else {
      window.alert("Your session will expire soon. Please save your work and refresh the page to stay signed in.")
    }
  }

  hideWarning() {
    this.warningShown = false
    const modalElement = document.getElementById("session-warning-modal")
    if (modalElement) {
      if (this.modal) {
        this.modal.hide()
      }
      modalElement.remove()
      this.modal = null
    }
  }

  async extendSession() {
    try {
      const response = await fetch(this.heartbeatUrlValue, {
        method: "GET",
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })

      if (response.ok) {
        this.lastActivityAt = Date.now()
        this.hideWarning()
      } else if (response.status === 401) {
        window.location.href = "/users/sign_in"
      }
    } catch (_error) {
      window.location.href = "/users/sign_in"
    }
  }
}

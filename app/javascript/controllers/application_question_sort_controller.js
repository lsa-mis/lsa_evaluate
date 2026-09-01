import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    if (typeof window.Sortable === "undefined") return

    this.sortable = window.Sortable.create(this.element, {
      animation: 150,
      handle: ".drag-handle",
      ghostClass: "table-active",
      filter: "select, input, button, a",
      preventOnFilter: false,
      onEnd: () => this.persistOrder()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  async persistOrder() {
    const ids = Array.from(this.element.querySelectorAll("[data-question-id]"))
      .map((row) => row.dataset.questionId)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ application_question_ids: ids })
      })

      if (!response.ok) this.reload()
    } catch (_error) {
      this.reload()
    }
  }

  reload() {
    window.location.reload()
  }
}

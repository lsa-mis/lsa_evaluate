import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["displayInput", "uidInput", "results"]

  connect() {
    this.timeout = null
  }

  lookup(event) {
    this.uidInputTarget.value = '' // Clear UID when typing
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.displayInputTarget.value.trim()
      if (query.length > 0) {
        fetch(`/containers/lookup_user?uid=${encodeURIComponent(query)}`)
          .then(response => response.json())
          .then(data => {
            this.showSuggestions(data)
          })
      } else {
        this.clearSuggestions()
      }
    }, 300)
  }

  showSuggestions(users) {
    this.clearSuggestions()
    users.forEach(user => {
      const option = document.createElement('div')
      option.textContent = user.display_name_and_uid
      option.classList.add('suggestion')
      option.addEventListener('click', () => {
        this.displayInputTarget.value = user.display_name_and_uid
        this.uidInputTarget.value = user.uid
        this.clearSuggestions()
      })
      this.resultsTarget.appendChild(option)
    })
  }

  clearSuggestions() {
    this.resultsTarget.innerHTML = ''
  }

  submit(event) {
    if (this.uidInputTarget.value.trim() === '') {
      event.preventDefault()
      alert('Please select a valid user.')
    }
  }
}
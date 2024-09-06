import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox_all", "checkbox", "form", "date_open", "date_closed"]

  connect() {
    console.log("connect - checkbox select/deselect all")
    this.checkboxTargets.map(x => x.checked = false)
    this.checkbox_allTarget.checked = false
  }

  toggleCheckbox() {
    var checkbox_error_place = document.getElementById('checkbox_error')
    checkbox_error_place.innerHTML = ''
    if (this.checkbox_allTarget.checked) {
      this.checkboxTargets.map(x => x.checked = true)
    } else {
      this.checkboxTargets.map(x => x.checked = false)
    }
  }

  toggleCheckboxAll() {
    var checkbox_error_place = document.getElementById('checkbox_error')
    checkbox_error_place.innerHTML = ''
    if (this.checkboxTargets.map(x => x.checked).includes(false)) {
      this.checkbox_allTarget.checked = false
    } else {
      this.checkbox_allTarget.checked = true
    }
  }

  submitForm(event) {
    var checkbox_error_place = document.getElementById('checkbox_error')
    checkbox_error_place.innerHTML = ''
    let date_open = this.date_openTarget.value
    let date_closed = this.date_closedTarget.value
    if (date_open == "" || date_closed == "") {
      checkbox_error_place.innerHTML = "Please select dates. "
      event.preventDefault()
    }
    if (date_open > date_closed) {
      checkbox_error_place.innerHTML = "Date Open should occur before Date Closed. "
      event.preventDefault()
    }
    if (!this.checkboxTargets.map(x => x.checked).includes(true)) {
      checkbox_error_place.innerHTML += "Please select descriptions."
      event.preventDefault()
    }
  }
}

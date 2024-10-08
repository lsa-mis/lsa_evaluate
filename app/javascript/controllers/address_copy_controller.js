import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "homeAddress1", "homeAddress2", "homeCity", "homeState", "homeZip", "homeCountry",
    "campusAddress1", "campusAddress2", "campusCity", "campusState", "campusZip", "campusCountry"
  ]

  copy() {
    this.homeAddress1Target.value = this.campusAddress1Target.value
    this.homeAddress2Target.value = this.campusAddress2Target.value
    this.homeCityTarget.value = this.campusCityTarget.value
    this.homeStateTarget.value = this.campusStateTarget.value
    this.homeZipTarget.value = this.campusZipTarget.value
    this.homeCountryTarget.value = this.campusCountryTarget.value
  }
}
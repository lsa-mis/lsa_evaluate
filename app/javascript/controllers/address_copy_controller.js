import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "homeAddress1", "homeAddress2", "homeCity", "homeState", "homeZip", "homePhone", "homeCountry",
    "campusAddress1", "campusAddress2", "campusCity", "campusState", "campusZip", "campusPhone", "campusCountry"
  ]

  copy() {
    this.campusAddress1Target.value = this.homeAddress1Target.value
    this.campusAddress2Target.value = this.homeAddress2Target.value
    this.campusCityTarget.value = this.homeCityTarget.value
    this.campusStateTarget.value = this.homeStateTarget.value
    this.campusZipTarget.value = this.homeZipTarget.value
    this.campusPhoneTarget.value = this.homePhoneTarget.value
    this.campusCountryTarget.value = this.homeCountryTarget.value
  }
}
import { Controller } from "@hotwired/stimulus"

// Toggles invite-list management UI based on access mode selection
export default class extends Controller {
  static targets = ["inviteListSection"]
  static values = { inviteListMode: { type: String, default: "invite_list" } }

  toggle(event) {
    const mode = event.target.value
    if (!this.hasInviteListSectionTarget) return

    if (mode === this.inviteListModeValue) {
      this.inviteListSectionTarget.classList.remove("d-none")
    } else {
      this.inviteListSectionTarget.classList.add("d-none")
    }
  }
}

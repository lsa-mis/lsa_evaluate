import { Controller } from "@hotwired/stimulus"

// Keeps invite-list management UI in sync with the *persisted* access mode.
// Selecting "Invite list only" without saving must not reveal invite forms —
// invite CRUD is only valid after access_mode is saved as invite_list.
export default class extends Controller {
  static targets = ["inviteListSection", "saveHint"]
  static values = {
    inviteListMode: { type: String, default: "invite_list" },
    initiallyInviteList: { type: Boolean, default: false }
  }

  toggle(event) {
    const mode = event.target.value
    if (!this.hasInviteListSectionTarget) return

    const selectingInviteList = mode === this.inviteListModeValue

    if (selectingInviteList && this.initiallyInviteListValue) {
      this.inviteListSectionTarget.classList.remove("d-none")
    } else {
      this.inviteListSectionTarget.classList.add("d-none")
    }

    if (this.hasSaveHintTarget) {
      const needsSave = selectingInviteList && !this.initiallyInviteListValue
      this.saveHintTarget.classList.toggle("d-none", !needsSave)
    }
  }
}

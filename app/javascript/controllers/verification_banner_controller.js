import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["resendButton"]

  resend(event) {
    // Disable the button to prevent multiple clicks
    if (this.hasResendButtonTarget) {
      this.resendButtonTarget.disabled = true
      this.resendButtonTarget.textContent = "Sending..."
    }
  }
}
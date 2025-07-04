import WebAuthnBaseController from "controllers/webauthn_base_controller"

export default class extends WebAuthnBaseController {
  static targets = [...WebAuthnBaseController.targets, "button"]

  disableWebAuthnElements() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
  }

  async authenticate() {
    if (!this.checkWebAuthnAvailability()) {
      return
    }

    this.buttonTarget.disabled = true
    
    try {
      await this.handleWebAuthnOperation(async () => {
        // Get authentication options from server
        const data = await this.fetchJSON("/customers/reauthentication", { method: "POST" })
        
        if (data.options) {
          // Hide button and show prompt
          this.hideButton()
          this.showPrompt()
          
          // Use the native parsing method to convert from JSON
          const options = PublicKeyCredential.parseRequestOptionsFromJSON(data.options)
          
          // Get credential for authentication
          const credential = await navigator.credentials.get({
            publicKey: options
          })
          
          // Convert credential to JSON format for sending to server
          const credentialJSON = credential.toJSON()
          
          // Send credential to server for verification
          const result = await this.fetchJSON("/customers/reauthentication/verify", {
            method: "POST",
            body: JSON.stringify(credentialJSON)
          })
          
          window.location.href = result.redirect_url
        }
      }, "Verification")
    } finally {
      this.buttonTarget.disabled = false
      this.hidePrompt()
    }
  }

  hideButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.parentElement.style.display = "none"
    }
  }

  showButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.parentElement.style.display = "block"
    }
  }

  showError(message) {
    super.showError(message)
    this.showButton()
  }
}
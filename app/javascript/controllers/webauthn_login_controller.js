import WebAuthnBaseController from "controllers/webauthn_base_controller"

export default class extends WebAuthnBaseController {
  static targets = [...WebAuthnBaseController.targets, "discoverableButton"]

  disableWebAuthnElements() {
    if (this.hasDiscoverableButtonTarget) {
      this.discoverableButtonTarget.disabled = true
    }
  }

  async signInWithDiscoverable() {
    console.log("signInWithDiscoverable called")
    
    await this.handleWebAuthnOperation(async () => {
      // Get discoverable credentials options from server
      const data = await this.fetchJSON("/customers/session/discoverable", { method: "POST" })
      
      if (data.options) {
        // Hide button and show prompt
        this.hideDiscoverableButton()
        this.showPrompt()
        
        // Use the native parsing method to convert from JSON
        const options = PublicKeyCredential.parseRequestOptionsFromJSON(data.options)
        
        // Get credential with empty allow list for discoverable credentials
        const credential = await navigator.credentials.get({
          publicKey: options,
          mediation: "optional" // This shows the browser's credential picker UI
        })
        
        // Convert credential to JSON format for sending to server
        const credentialJSON = credential.toJSON()
        
        // Send credential to server
        const result = await this.fetchJSON("/customers/session/verify", {
          method: "POST",
          body: JSON.stringify(credentialJSON)
        })
        
        window.location.href = result.redirect_url
      }
    }, "Authentication")
  }

  hideDiscoverableButton() {
    if (this.hasDiscoverableButtonTarget) {
      this.discoverableButtonTarget.style.display = "none"
    }
  }

  showDiscoverableButton() {
    if (this.hasDiscoverableButtonTarget) {
      this.discoverableButtonTarget.style.display = "block"
    }
  }


  showError(message) {
    super.showError(message)
    this.showDiscoverableButton()
  }
}
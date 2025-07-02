import WebAuthnBaseController from "controllers/webauthn_base_controller"

export default class extends WebAuthnBaseController {
  static targets = [...WebAuthnBaseController.targets, "nickname", "button"]

  disableWebAuthnElements() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
  }

  async register() {
    if (!this.checkWebAuthnAvailability()) {
      return
    }

    this.buttonTarget.disabled = true
    
    try {
      await this.handleWebAuthnOperation(async () => {
        this.showPrompt()
        
        // Get creation options from server
        const optionsJSON = await this.fetchJSON("/customers/credentials", { method: "POST" })
        
        // Use the native parsing method to convert from JSON
        const options = PublicKeyCredential.parseCreationOptionsFromJSON(optionsJSON.options)
        
        // Create credential using native API
        const credential = await navigator.credentials.create({
          publicKey: options
        })
        
        // Convert credential to JSON format for sending to server
        const credentialJSON = credential.toJSON()
        
        // Add nickname to the credential data
        const credentialData = {
          ...credentialJSON,
          nickname: this.nicknameTarget.value
        }
        
        // Send credential to server for verification
        const result = await this.fetchJSON("/customers/credentials/verify", {
          method: "POST",
          body: JSON.stringify(credentialData)
        })
        
        window.location.href = result.redirect_url
      }, "register")
    } finally {
      this.buttonTarget.disabled = false
      this.hidePrompt()
    }
  }

}
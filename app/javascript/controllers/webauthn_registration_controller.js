import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nickname", "button", "prompt", "error", "errorText"]

  connect() {
    // Check if WebAuthn is available
    if (!window.PublicKeyCredential) {
      if (!window.isSecureContext) {
        this.showError("Passwordless authentication requires HTTPS. Please access this site using https:// or from localhost.")
      } else {
        this.showError("Your browser doesn't support passwordless authentication. Please use a modern browser.")
      }
      this.buttonTarget.disabled = true
    }
  }

  async register() {
    // Double-check WebAuthn availability with better error messages
    if (!window.PublicKeyCredential) {
      if (!window.isSecureContext) {
        this.showError("This page must be served over HTTPS to use passwordless authentication.")
      } else {
        this.showError("WebAuthn is not available. Please check your browser settings.")
      }
      return
    }

    this.buttonTarget.disabled = true
    this.promptTarget.classList.remove("hidden")
    this.errorTarget.classList.add("hidden")
    
    try {
      // Get creation options from server
      const optionsResponse = await fetch("/customers/credentials", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken()
        }
      })
      
      if (!optionsResponse.ok) {
        const error = await optionsResponse.json()
        throw new Error(error.error || "Failed to get registration options")
      }
      
      const optionsJSON = await optionsResponse.json()
      
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
      const verifyResponse = await fetch("/customers/credentials/verify", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken()
        },
        body: JSON.stringify(credentialData)
      })
      
      const result = await verifyResponse.json()
      
      if (verifyResponse.ok) {
        window.location.href = result.redirect_url
      } else {
        this.showError(result.error || "Registration failed")
      }
      
    } catch (error) {
      console.error("WebAuthn error:", error)
      
      let errorMessage = "Registration failed. "
      if (error.name === "NotAllowedError") {
        errorMessage += "The operation was cancelled or not allowed."
      } else if (error.name === "InvalidStateError") {
        errorMessage += "This authenticator may already be registered."
      } else if (error.name === "NotSupportedError") {
        errorMessage += "Your browser doesn't support this type of credential."
      } else if (error.name === "SecurityError") {
        errorMessage += "This operation requires a secure context (HTTPS)."
      } else {
        errorMessage += error.message || "Please try again."
      }
      
      this.showError(errorMessage)
    } finally {
      this.buttonTarget.disabled = false
      this.promptTarget.classList.add("hidden")
    }
  }

  showError(message) {
    this.errorTextTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
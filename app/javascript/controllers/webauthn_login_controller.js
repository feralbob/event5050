import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "error", "errorText", "discoverableButton"]

  connect() {
    // Check if WebAuthn is available
    if (!window.PublicKeyCredential) {
      if (!window.isSecureContext) {
        this.showError("Passwordless authentication requires HTTPS. Please access this site using https:// or from localhost.")
        if (this.hasDiscoverableButtonTarget) this.discoverableButtonTarget.disabled = true
      }
    }
  }

  async signInWithDiscoverable() {
    console.log("signInWithDiscoverable called")
    
    // Hide any previous errors
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }

    try {
      // Get discoverable credentials options from server
      const response = await fetch("/customers/session/discoverable", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken()
        }
      })

      if (!response.ok) {
        throw new Error("Failed to get authentication options")
      }

      const data = await response.json()
      
      if (data.options) {
        // Hide button and show prompt
        if (this.hasDiscoverableButtonTarget) {
          this.discoverableButtonTarget.style.display = "none"
        }
        this.promptTarget.classList.remove("hidden")
        
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
        const verifyResponse = await fetch("/customers/session/verify", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": this.getCSRFToken()
          },
          body: JSON.stringify(credentialJSON)
        })
        
        const result = await verifyResponse.json()
        
        if (verifyResponse.ok) {
          window.location.href = result.redirect_url
        } else {
          this.showError(result.error || "Authentication failed")
        }
      }
    } catch (error) {
      console.error("WebAuthn error:", error)
      
      let errorMessage = "Authentication failed. "
      if (error.name === "NotAllowedError") {
        errorMessage += "The operation was cancelled or timed out."
      } else if (error.name === "SecurityError") {
        errorMessage += "This operation requires a secure context (HTTPS)."
      } else if (error.name === "InvalidStateError") {
        errorMessage += "No credentials available for this device."
      } else {
        errorMessage += "Please try again or use email sign in."
      }
      
      this.showError(errorMessage)
    }
  }


  showError(message) {
    this.errorTextTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.promptTarget.classList.add("hidden")
    
    // Show the button again if it was hidden
    if (this.hasDiscoverableButtonTarget) {
      this.discoverableButtonTarget.style.display = "block"
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
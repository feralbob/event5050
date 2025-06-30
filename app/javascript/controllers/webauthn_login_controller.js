import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "submit", "prompt", "error", "errorText"]

  connect() {
    this.element.addEventListener("ajax:success", this.handleSuccess.bind(this))
    this.element.addEventListener("ajax:error", this.handleError.bind(this))
    
    // Check if WebAuthn is available
    if (!window.PublicKeyCredential) {
      if (!window.isSecureContext) {
        this.showError("Passwordless authentication requires HTTPS. Please access this site using https:// or from localhost.")
        this.submitTarget.disabled = true
      }
    }
  }

  async handleSuccess(event) {
    const response = event.detail[0]
    
    if (response.options) {
      // Hide form and show prompt
      this.element.style.display = "none"
      this.promptTarget.classList.remove("hidden")
      
      try {
        // Use the native parsing method to convert from JSON
        const options = PublicKeyCredential.parseRequestOptionsFromJSON(response.options)
        
        // Get credential
        const credential = await navigator.credentials.get({
          publicKey: options
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
      } catch (error) {
        console.error("WebAuthn error:", error)
        
        let errorMessage = "Authentication failed. "
        if (error.name === "NotAllowedError") {
          errorMessage += "The operation was cancelled or timed out."
        } else if (error.name === "SecurityError") {
          errorMessage += "This operation requires a secure context (HTTPS)."
        } else {
          errorMessage += "Please try again."
        }
        
        this.showError(errorMessage)
      }
    }
  }

  handleError(event) {
    const response = event.detail[0]
    const error = response.error || "An error occurred. Please try again."
    this.showError(error)
  }

  showError(message) {
    this.errorTextTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.promptTarget.classList.add("hidden")
    this.element.style.display = "block"
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
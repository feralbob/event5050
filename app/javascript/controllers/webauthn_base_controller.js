import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "error", "errorText"]

  connect() {
    this.checkWebAuthnAvailability()
  }

  checkWebAuthnAvailability() {
    if (!window.PublicKeyCredential) {
      const message = !window.isSecureContext
        ? "Passwordless authentication requires HTTPS. Please access this site using https:// or from localhost."
        : "Your browser doesn't support passwordless authentication. Please use a modern browser."
      
      this.showError(message)
      this.disableWebAuthnElements()
      return false
    }
    return true
  }

  // Override in subclasses to disable specific elements
  disableWebAuthnElements() {
    // Subclasses can override this
  }

  async fetchJSON(url, options = {}) {
    const defaultOptions = {
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCSRFToken()
      }
    }

    const response = await fetch(url, { ...defaultOptions, ...options })
    const data = await response.json()

    if (!response.ok) {
      throw new Error(data.error || "Request failed")
    }

    return data
  }

  showError(message) {
    if (this.hasErrorTextTarget) {
      this.errorTextTarget.textContent = message
    }
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove("hidden")
    }
    if (this.hasPromptTarget) {
      this.promptTarget.classList.add("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }

  showPrompt() {
    if (this.hasPromptTarget) {
      this.promptTarget.classList.remove("hidden")
    }
  }

  hidePrompt() {
    if (this.hasPromptTarget) {
      this.promptTarget.classList.add("hidden")
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }

  getWebAuthnErrorMessage(error, action = "Operation") {
    const errorMessages = {
      NotAllowedError: "The operation was cancelled or timed out.",
      SecurityError: "This operation requires a secure context (HTTPS).",
      InvalidStateError: action === "register" 
        ? "This authenticator may already be registered." 
        : "No credentials available for this device.",
      NotSupportedError: "Your browser doesn't support this type of credential.",
      AbortError: "The operation was aborted.",
      ConstraintError: "The authenticator doesn't meet the requirements.",
      UnknownError: "An unknown error occurred.",
      TypeError: "Invalid parameters provided."
    }

    const baseMessage = `${action} failed. `
    const specificMessage = errorMessages[error.name] || error.message || "Please try again."
    
    return baseMessage + specificMessage
  }

  async handleWebAuthnOperation(operation, action = "Operation") {
    try {
      this.hideError()
      const result = await operation()
      return result
    } catch (error) {
      console.error(`WebAuthn ${action} error:`, error)
      this.showError(this.getWebAuthnErrorMessage(error, action))
      throw error
    }
  }
}
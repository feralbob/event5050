class WebauthnService
  class << self
    def configuration
      # Always reconfigure to ensure proper origin is set
      WebAuthn.configure do |config|
        config.origin = Rails.application.config.webauthn_origin
        config.rp_name = Rails.application.config.webauthn_rp_name
        config.rp_id = Rails.application.config.webauthn_rp_id
      end
      WebAuthn.configuration
    end

    def generate_challenge
      WebAuthn::Credential.options_for_create(
        user: { id: WebAuthn.generate_user_id, name: "", display_name: "" },
        exclude: []
      )
    end

    def credential_creation_options(customer)
      # Ensure configuration is loaded
      configuration
      
      WebAuthn::Credential.options_for_create(
        user: {
          id: customer.webauthn_id,
          name: customer.email,
          display_name: customer.full_name
        },
        rp: {
          name: configuration.rp_name,
          id: configuration.rp_id
        },
        exclude: customer.credentials_for_get,
        authenticator_selection: {
          authenticator_attachment: "platform",
          user_verification: "preferred"
        }
      )
    end

    def credential_request_options(customer = nil)
      # Ensure configuration is loaded
      configuration
      
      options = {
        allow: customer&.credentials_for_get || [],
        user_verification: "preferred"
      }

      WebAuthn::Credential.options_for_get(**options)
    end

    def verify_registration(customer, params)
      # Ensure configuration is loaded
      configuration
      
      webauthn_credential = WebAuthn::Credential.from_create(params)

      webauthn_credential.verify(params[:challenge])

      webauthn_credential
    end

    def verify_authentication(params, challenge)
      # Ensure configuration is loaded
      configuration
      
      webauthn_credential = WebAuthn::Credential.from_get(params)

      # Find the customer by credential
      credential = WebauthnCredential.find_by!(external_id: params[:id])
      customer = credential.customer

      # Verify the assertion
      webauthn_credential.verify(
        challenge,
        public_key: credential.public_key_object,
        sign_count: credential.sign_count,
        user_verification: true
      )

      [ customer, webauthn_credential ]
    end

    private

    def request_origin
      if Rails.env.development?
        "http://localhost:3000"
      else
        "https://#{request_host}"
      end
    end

    def request_host
      Rails.application.config.hosts.first || "localhost"
    end
  end
end

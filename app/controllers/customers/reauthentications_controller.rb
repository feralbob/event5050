class Customers::ReauthenticationsController < Customers::BaseController
  def new
    # Show reauthentication form
  end

  def create
    # Generate WebAuthn challenge for reauthentication
    options = WebauthnService.credential_request_options(current_customer)
    session[:webauthn_reauthentication_challenge] = options.challenge
    
    render json: {
      options: options.as_json
    }
  end

  def verify
    challenge = session[:webauthn_reauthentication_challenge]

    unless challenge
      return render json: { error: "Invalid session" }, status: :unprocessable_entity
    end

    begin
      customer, webauthn_credential = WebauthnService.verify_authentication(
        credential_params,
        challenge
      )

      if customer && customer.id == current_customer.id
        # Clear temporary session data
        session.delete(:webauthn_reauthentication_challenge)
        
        # Mark authentication as recent
        session[:last_auth_at] = Time.current.to_s
        
        # Update credential usage
        customer.update_credential_after_authentication(webauthn_credential)

        # Redirect to original destination
        redirect_url = session.delete(:return_to) || customers_credentials_path
        render json: { redirect_url: redirect_url }
      else
        render json: { error: "Authentication failed" }, status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn reauthentication error: #{e.message}"
      render json: { error: "Authentication failed: #{e.message}" },
             status: :unprocessable_entity
    end
  end

  private

  def credential_params
    params.permit(:id, :rawId, :type, :authenticatorAttachment,
                  clientExtensionResults: {},
                  response: [ :clientDataJSON, :authenticatorData, :signature, :userHandle ])
  end
end
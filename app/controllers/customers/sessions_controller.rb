class Customers::SessionsController < ApplicationController
  before_action :require_no_authentication, only: [ :new, :create, :discoverable, :verify ]
  before_action :require_authentication, only: [ :destroy ]

  def new
    # Show sign in form
  end

  def create
    # Redirect to new session path since we only support discoverable credentials
    redirect_to new_customers_session_path,
                alert: "Please use the 'Sign in with passkey' button to authenticate."
  end

  def discoverable
    # Generate WebAuthn challenge for discoverable credentials (no customer needed)
    options = WebauthnService.credential_request_options
    session[:webauthn_challenge] = options.challenge

    render json: {
      options: options.as_json
    }
  end

  def verify
    challenge = session[:webauthn_challenge]

    unless challenge
      return render json: { error: "Invalid session" }, status: :unprocessable_entity
    end

    begin
      customer, webauthn_credential = WebauthnService.verify_authentication(
        credential_params,
        challenge
      )

      if customer
        # Clear temporary session data
        session.delete(:webauthn_challenge)
        session.delete(:attempting_customer_id)

        # Sign in the customer
        sign_in_customer(customer)
        customer.update_credential_after_authentication(webauthn_credential)

        render json: { redirect_url: redirect_url_after_sign_in }
      else
        render json: { error: "This security key is not registered with any account. Please sign up first or use a registered key." },
               status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn verification error: #{e.message}"
      render json: { error: "Authentication failed: #{e.message}" },
             status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.info "Credential not found: #{e.message}"
      render json: { error: "This security key is not registered with your account. Please sign up or use a registered key." },
             status: :unprocessable_entity
    end
  end

  def destroy
    sign_out_customer
    redirect_to root_path, notice: "You have been signed out."
  end

  private

  def require_authentication
    unless customer_signed_in?
      redirect_to new_customers_session_path, alert: "Please sign in to continue."
    end
  end

  def credential_params
    params.permit(:id, :rawId, :type, :authenticatorAttachment,
                  clientExtensionResults: {},
                  response: [ :clientDataJSON, :authenticatorData, :signature, :userHandle ])
  end

  def require_no_authentication
    if customer_signed_in?
      redirect_to root_path, notice: "You are already signed in."
    end
  end

  def sign_in_customer(customer)
    reset_session
    session[:customer_id] = customer.id
    customer.update_sign_in_info(request.remote_ip)
  end

  def sign_out_customer
    session.delete(:customer_id)
    reset_session
    @current_customer = nil
  end

  def redirect_url_after_sign_in
    session.delete(:return_to) || root_path
  end
end

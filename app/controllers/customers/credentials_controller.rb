class Customers::CredentialsController < Customers::BaseController
  skip_before_action :authenticate_customer!, only: [ :new, :create, :verify ]
  before_action :require_pending_setup, only: [ :new ]
  before_action :set_credential, only: [ :destroy ]

  def index
    @credentials = current_customer.webauthn_credentials.recently_used
  end

  def new
    @customer = Customer.find(session[:pending_credential_setup])
  end

  def create
    customer = find_customer_for_credential_creation

    unless customer
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    options = WebauthnService.credential_creation_options(customer)
    session[:webauthn_challenge] = options.challenge
    session[:credential_creation_customer_id] = customer.id

    # Convert to the format expected by the native WebAuthn API
    render json: { options: options.as_json }
  end

  def verify
    customer_id = session[:credential_creation_customer_id]
    challenge = session[:webauthn_challenge]

    unless customer_id && challenge
      return render json: { error: "Invalid session" }, status: :unprocessable_entity
    end

    customer = Customer.find(customer_id)

    begin
      webauthn_credential = WebauthnService.verify_registration(
        customer,
        credential_params.merge(challenge: challenge)
      )

      credential = customer.add_webauthn_credential(
        webauthn_credential,
        nickname: params[:nickname]
      )

      # Clear temporary session data
      session.delete(:webauthn_challenge)
      session.delete(:credential_creation_customer_id)
      session.delete(:pending_credential_setup)

      # Sign in the customer if this was initial setup
      if !customer_signed_in?
        sign_in_customer(customer)
        render json: { redirect_url: root_path, message: "Setup complete! You are now signed in." }
      else
        render json: {
          redirect_url: customers_credentials_path,
          message: "Security key added successfully."
        }
      end
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn registration error: #{e.message}"
      render json: { error: "Registration failed: #{e.message}" },
             status: :unprocessable_entity
    end
  end

  def destroy
    if current_customer.can_delete_credential?(@credential)
      @credential.destroy
      redirect_to customers_credentials_path, notice: "Security key removed successfully."
    else
      redirect_to customers_credentials_path, alert: "You must keep at least one security key."
    end
  end

  private

  def require_pending_setup
    unless session[:pending_credential_setup]
      redirect_to customers_credentials_path
    end
  end

  def find_customer_for_credential_creation
    if session[:pending_credential_setup]
      Customer.find_by(id: session[:pending_credential_setup])
    elsif customer_signed_in?
      current_customer
    end
  end

  def set_credential
    @credential = current_customer.webauthn_credentials.find(params[:id])
  end

  def credential_params
    # The toJSON() method sends authenticatorAttachment, clientExtensionResults, etc.
    params.permit(:id, :rawId, :type, :authenticatorAttachment, :nickname,
                  clientExtensionResults: {},
                  response: [ :clientDataJSON, :attestationObject, :authenticatorData, :signature, :userHandle, :publicKey, :publicKeyAlgorithm, { transports: [] } ])
  end
end

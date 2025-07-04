class Customers::ConfirmationsController < ApplicationController
  # Allow signed-in users to confirm their email
  def show
    customer = Customer.find_by(confirmation_token: params[:token])

    if customer && !customer.confirmed?
      customer.confirm!
      
      if customer_signed_in? && current_customer.id == customer.id
        # User is already signed in, just update their status
        redirect_to root_path,
                    notice: "Your email has been confirmed successfully!"
      elsif customer.webauthn_credentials.exists?
        # User has credentials, redirect to sign in
        redirect_to new_customers_session_path,
                    notice: "Your email has been confirmed. Please sign in to continue."
      else
        # User needs to set up credentials
        session[:pending_credential_setup] = customer.id
        redirect_to new_customers_credential_path,
                    notice: "Your email has been confirmed. Please set up your security key."
      end
    else
      redirect_to new_customers_session_path,
                  alert: "Invalid or expired confirmation link."
    end
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.unconfirmed.find_by(email: params.dig(:customer, :email)&.downcase)

    if @customer
      @customer.generate_confirmation_token!
      CustomerMailer.confirmation_instructions(@customer).deliver_later
      redirect_to pending_customers_registrations_path,
                  notice: "Confirmation instructions have been sent to your email."
    else
      @customer = Customer.new(email: params.dig(:customer, :email))
      @customer.errors.add(:email, "not found or already confirmed")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_no_authentication
    if customer_signed_in?
      redirect_to root_path, notice: "You are already signed in."
    end
  end
end

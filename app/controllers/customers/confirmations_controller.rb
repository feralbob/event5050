class Customers::ConfirmationsController < ApplicationController
  before_action :require_no_authentication, only: [ :show ]
  def show
    customer = Customer.find_by(confirmation_token: params[:token])

    if customer && !customer.confirmed?
      customer.confirm!
      session[:pending_credential_setup] = customer.id
      redirect_to new_customers_credential_path,
                  notice: "Your email has been confirmed. Please set up your security key."
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

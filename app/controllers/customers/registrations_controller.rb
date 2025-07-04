class Customers::RegistrationsController < ApplicationController
  before_action :require_no_authentication, except: [ :pending ]

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      @customer.generate_confirmation_token!
      CustomerMailer.confirmation_instructions(@customer).deliver_later
      
      # Sign in the customer immediately
      session[:customer_id] = @customer.id
      session[:pending_credential_setup] = @customer.id
      
      # Redirect to security key setup
      redirect_to new_customers_credential_path,
                  notice: "Welcome! Please set up your security key. We've sent a confirmation email to #{@customer.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def pending
    # Show pending confirmation page
  end

  private

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :email, :phone)
  end

  def require_no_authentication
    if customer_signed_in?
      redirect_to root_path, notice: "You are already signed in."
    end
  end
end

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
      redirect_to pending_customers_registrations_path
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

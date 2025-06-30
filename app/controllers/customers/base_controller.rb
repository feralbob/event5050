class Customers::BaseController < ApplicationController
  before_action :authenticate_customer!

  private

  def authenticate_customer!
    unless current_customer
      store_location
      redirect_to new_customers_session_path, alert: "Please sign in to continue."
    end
  end

  def current_customer
    @current_customer ||= find_customer_from_session
  end
  helper_method :current_customer

  def customer_signed_in?
    current_customer.present?
  end
  helper_method :customer_signed_in?

  def find_customer_from_session
    return nil unless session[:customer_id]

    Customer.confirmed.find_by(id: session[:customer_id])
  rescue ActiveRecord::RecordNotFound
    session.delete(:customer_id)
    nil
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

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def redirect_back_or_default(default)
    redirect_to(session.delete(:return_to) || default)
  end

  def require_no_authentication
    if customer_signed_in?
      redirect_to root_path, notice: "You are already signed in."
    end
  end
end

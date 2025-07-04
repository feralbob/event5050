class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Set up multitenancy
  set_current_tenant_through_filter
  before_action :set_current_organization

  private

  def set_current_organization
    # For now, we'll set the tenant based on the current org_user's organization
    # This will be refined as we implement authentication
    if current_org_user
      set_current_tenant(current_org_user.organization)
    end
  end

  def current_organization
    current_tenant
  end

  # Customer authentication helpers
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

    Customer.find_by(id: session[:customer_id])
  rescue ActiveRecord::RecordNotFound
    session.delete(:customer_id)
    nil
  end
  
  def email_verified?
    customer_signed_in? && current_customer.confirmed?
  end
  helper_method :email_verified?
  
  def require_verified_email!
    unless email_verified?
      redirect_to root_path, alert: "Please verify your email address to continue. Check your inbox for the confirmation email."
    end
  end
end

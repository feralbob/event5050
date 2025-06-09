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
end

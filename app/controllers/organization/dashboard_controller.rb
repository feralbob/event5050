class Organization::DashboardController < ApplicationController
  before_action :authenticate_org_user!

  def index
    # Dashboard view for organization users
  end
end

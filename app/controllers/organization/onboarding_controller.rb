class Organization::OnboardingController < ApplicationController
  include Wicked::Wizard

  steps :org_user_details, :organization_info, :confirmation

  def show
    case step
    when :org_user_details
      @org_user = OrgUser.new
    when :organization_info
      if session[:onboarding_org_user_id].nil?
        redirect_to organization_onboarding_path(:org_user_details) and return
      end
      @organization = Organization.new
    when :confirmation
      if current_onboarding_user.nil?
        redirect_to organization_onboarding_path(:org_user_details) and return
      end
      @org_user = current_onboarding_user
      @organization = @org_user.organization
    end

    render_wizard
  end

  def update
    case step
    when :org_user_details
      @org_user = OrgUser.new(org_user_params)
      # For onboarding, create a temporary organization
      temp_org = Organization.create!(name: "Temp-#{SecureRandom.hex(4)}")
      @org_user.organization = temp_org

      if @org_user.save
        session[:onboarding_org_user_id] = @org_user.id
        redirect_to next_wizard_path
      else
        render_wizard
      end

    when :organization_info
      @org_user = current_onboarding_user
      return redirect_to organization_onboarding_path(:org_user_details) unless @org_user

      @organization = Organization.new(organization_params)

      if @organization.save
        # Update the user's organization from temp to real one
        old_org = @org_user.organization

        ActsAsTenant.with_mutable_tenant do
          @org_user.update!(organization: @organization)
        end
        old_org.destroy! # Clean up temp organization

        redirect_to next_wizard_path
      else
        render_wizard
      end

    when :confirmation
      @org_user = current_onboarding_user
      return redirect_to organization_onboarding_path(:org_user_details) unless @org_user

      # Sign in the user and clear session
      sign_in(:org_user, @org_user)
      session.delete(:onboarding_org_user_id)

      redirect_to organization_dashboard_path, notice: "Welcome to Event5050!"
    end
  end

  private

  def org_user_params
    params.require(:org_user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def organization_params
    params.require(:organization).permit(:name, :description)
  end

  def current_onboarding_user
    @current_onboarding_user ||= OrgUser.find_by(id: session[:onboarding_org_user_id])
  end

  def finish_wizard_path
    organization_dashboard_path
  end
end

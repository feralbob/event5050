require "test_helper"

class Organization::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    skip "Skipping onboarding tests"
  end

  test "should show org_user_details step" do
    get organization_onboarding_path(id: :org_user_details)
    assert_response :success
    assert_select "h1", text: /Create Your Account/i
  end

  test "should create org user and proceed to organization_info step" do
    assert_difference "OrgUser.count", 1 do
      put organization_onboarding_path(id: :org_user_details), params: {
        org_user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "John",
          last_name: "Doe"
        }
      }
    end

    assert_redirected_to organization_onboarding_path(id: :organization_info)
    # Session is available in follow_redirect
    follow_redirect!
    assert_response :success
  end

  test "should show organization_info step" do
    # Create a user and set up session
    org_user = OrgUser.create!(
      email: "test@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "User",
      organization: Organization.create!(name: "Temp Org")
    )

    # Simulate having gone through step 1
    post organization_onboarding_path(id: :org_user_details), params: {
      org_user: {
        email: "test2@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "Test2",
        last_name: "User2"
      }
    }

    get organization_onboarding_path(id: :organization_info)
    assert_response :success
    assert_select "h1", text: /Organization Information/i
  end

  test "should create organization and proceed to confirmation step" do
    # First create a user through step 1
    post organization_onboarding_path(id: :org_user_details), params: {
      org_user: {
        email: "test3@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "Test3",
        last_name: "User3"
      }
    }

    assert_difference "Organization.count", 0 do # Temp org already created, old one destroyed
      put organization_onboarding_path(id: :organization_info),
           params: {
             organization: {
               name: "New Organization",
               description: "A new organization for testing"
             }
           }
    end

    assert_redirected_to organization_onboarding_path(id: :confirmation)
  end

  test "should complete onboarding and redirect to dashboard" do
    # Go through all steps
    post organization_onboarding_path(id: :org_user_details), params: {
      org_user: {
        email: "test4@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "Test4",
        last_name: "User4"
      }
    }

    post organization_onboarding_path(id: :organization_info), params: {
      organization: {
        name: "Final Organization",
        description: "Final org for testing"
      }
    }

    put organization_onboarding_path(id: :confirmation)

    assert_redirected_to organization_dashboard_path
    assert_equal "Welcome to Event5050!", flash[:notice]
  end
end

require "test_helper"

class Customers::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = Customer.create!(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com"
    )
    @customer.generate_confirmation_token!
  end

  test "should confirm email with valid token" do
    get customers_confirmations_path(@customer.confirmation_token)

    @customer.reload
    assert @customer.confirmed?
    assert_nil @customer.confirmation_token

    assert_redirected_to new_customers_credential_path
    assert_equal "Your email has been confirmed. Please set up your security key.", flash[:notice]
  end

  test "should not confirm with invalid token" do
    get customers_confirmations_path("invalid-token")

    @customer.reload
    assert_not @customer.confirmed?

    assert_redirected_to new_customers_session_path
    assert_equal "Invalid or expired confirmation link.", flash[:alert]
  end

  test "should not confirm already confirmed customer" do
    @customer.confirm!

    get customers_confirmations_path("any-token")

    assert_redirected_to new_customers_session_path
    assert_equal "Invalid or expired confirmation link.", flash[:alert]
  end

  test "should get new" do
    get new_customers_confirmation_path
    assert_response :success
  end

  test "should resend confirmation instructions" do
    post customers_confirmations_path, params: {
      customer: { email: @customer.email }
    }

    assert_redirected_to pending_customers_registrations_path
    assert_equal "Confirmation instructions have been sent to your email.", flash[:notice]
  end

  test "should not resend for non-existent email" do
    post customers_confirmations_path, params: {
      customer: { email: "nonexistent@example.com" }
    }

    assert_response :unprocessable_entity
  end

  test "should not resend for already confirmed customer" do
    @customer.confirm!

    post customers_confirmations_path, params: {
      customer: { email: @customer.email }
    }

    assert_response :unprocessable_entity
  end
end

require "test_helper"

class Customers::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
  end

  test "should get new" do
    get new_customers_session_path
    assert_response :success
  end

  test "should start authentication for existing customer" do
    post customers_session_path, params: {
      session: { email: @customer.email }
    }

    assert_response :success
    assert session[:webauthn_challenge].present?
  end

  test "should return error for non-existent email" do
    post customers_session_path, params: {
      session: { email: "nonexistent@example.com" }
    }

    assert_response :unprocessable_entity
  end

  test "should return error for unconfirmed customer" do
    @customer.update!(email_confirmed_at: nil)

    post customers_session_path, params: {
      session: { email: @customer.email }
    }

    assert_response :unprocessable_entity
  end

  test "should verify webauthn and sign in" do
    # This would need proper WebAuthn mocking in a real test
    skip "WebAuthn verification requires complex mocking"
  end

  test "should sign out" do
    sign_in_as(@customer)

    delete customers_session_path
    assert_redirected_to root_path
    assert_nil session[:customer_id]
  end

  test "should redirect if already signed in" do
    sign_in_as(@customer)

    get new_customers_session_path
    assert_redirected_to root_path
  end
end

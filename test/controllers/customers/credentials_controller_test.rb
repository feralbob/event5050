require "test_helper"

class Customers::CredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    sign_in_as(@customer)
  end

  test "should get index" do
    get customers_credentials_path
    assert_response :success
  end

  test "should get new for pending setup" do
    session[:pending_credential_setup] = @customer.id

    get new_customers_credential_path
    assert_response :success
  end

  test "should redirect new if no pending setup" do
    session.delete(:pending_credential_setup)

    get new_customers_credential_path
    assert_redirected_to customers_credentials_path
  end

  test "should start credential creation" do
    post customers_credentials_path, params: { format: :json }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["options"].present?
    assert session[:webauthn_challenge].present?
  end

  test "should verify and create credential" do
    skip "WebAuthn credential creation requires complex mocking"
  end

  test "should delete credential if multiple exist" do
    # Create a second credential
    @customer.webauthn_credentials.create!(
      external_id: "second_credential",
      public_key: Base64.strict_encode64("test_key"),
      sign_count: 0
    )

    credential = @customer.webauthn_credentials.first

    assert_difference("@customer.webauthn_credentials.count", -1) do
      delete customers_credential_path(credential)
    end

    assert_redirected_to customers_credentials_path
    assert_equal "Security key removed successfully.", flash[:notice]
  end

  test "should not delete last credential" do
    # Ensure only one credential exists
    @customer.webauthn_credentials.where.not(id: @customer.webauthn_credentials.first.id).destroy_all
    credential = @customer.webauthn_credentials.first

    assert_no_difference("@customer.webauthn_credentials.count") do
      delete customers_credential_path(credential)
    end

    assert_redirected_to customers_credentials_path
    assert_equal "You must keep at least one security key.", flash[:alert]
  end

  test "should require authentication" do
    sign_out_customer

    get customers_credentials_path
    assert_redirected_to new_customers_session_path
  end
end

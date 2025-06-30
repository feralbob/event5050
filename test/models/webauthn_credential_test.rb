require "test_helper"

class WebauthnCredentialTest < ActiveSupport::TestCase
  def setup
    @customer = customers(:one)
    @credential = webauthn_credentials(:one)
  end

  test "should belong to customer" do
    assert_respond_to @credential, :customer
    assert_equal @customer, @credential.customer
  end

  test "should require external_id" do
    credential = WebauthnCredential.new(
      customer: @customer,
      public_key: Base64.strict_encode64("test_key"),
      sign_count: 0
    )
    assert_not credential.valid?
    assert_includes credential.errors[:external_id], "can't be blank"
  end

  test "should require unique external_id" do
    duplicate = WebauthnCredential.new(
      customer: @customer,
      external_id: @credential.external_id,
      public_key: Base64.strict_encode64("test_key"),
      sign_count: 0
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "has already been taken"
  end

  test "should require public_key" do
    credential = WebauthnCredential.new(
      customer: @customer,
      external_id: "unique_id",
      sign_count: 0
    )
    assert_not credential.valid?
    assert_includes credential.errors[:public_key], "can't be blank"
  end

  test "should have default sign_count of 0" do
    credential = WebauthnCredential.new(
      customer: @customer,
      external_id: "unique_id",
      public_key: Base64.strict_encode64("test_key")
    )
    assert credential.valid?
    assert_equal 0, credential.sign_count
  end

  test "sign_count should be non-negative" do
    credential = WebauthnCredential.new(
      customer: @customer,
      external_id: "unique_id",
      public_key: Base64.strict_encode64("test_key"),
      sign_count: -1
    )
    assert_not credential.valid?
    assert_includes credential.errors[:sign_count], "must be greater than or equal to 0"
  end

  test "should have credential_id method" do
    assert_equal @credential.external_id, @credential.credential_id
  end

  test "should have public_key_object method" do
    encoded_key = Base64.strict_encode64("test_key_data")
    credential = WebauthnCredential.new(
      external_id: "test",
      public_key: encoded_key
    )

    assert_equal "test_key_data", credential.public_key_object
  end

  test "should have recently_used scope" do
    # Create credentials with different last_used_at times
    old_credential = @customer.webauthn_credentials.create!(
      external_id: "old_credential",
      public_key: Base64.strict_encode64("old_key"),
      sign_count: 0,
      last_used_at: 2.days.ago
    )

    recent_credential = @customer.webauthn_credentials.create!(
      external_id: "recent_credential",
      public_key: Base64.strict_encode64("recent_key"),
      sign_count: 0,
      last_used_at: 1.hour.ago
    )

    # Test the scope
    credentials = @customer.webauthn_credentials.recently_used
    assert_equal recent_credential, credentials.first
    assert_equal old_credential, credentials.second
  end

  test "should allow nickname and name fields" do
    credential = WebauthnCredential.new(
      customer: @customer,
      external_id: "unique_id",
      public_key: Base64.strict_encode64("test_key"),
      sign_count: 0,
      nickname: "My Security Key",
      name: "YubiKey 5C"
    )

    assert credential.valid?
    assert_equal "My Security Key", credential.nickname
    assert_equal "YubiKey 5C", credential.name
  end
end

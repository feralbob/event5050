require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "should have email" do
    customer = Customer.new(
      first_name: "John",
      last_name: "Doe",
      phone: "555-1234"
    )
    assert_not customer.valid?
    assert_includes customer.errors[:email], "can't be blank"
  end

  test "should have valid email format" do
    customer = Customer.new(
      first_name: "John",
      last_name: "Doe",
      email: "invalid.email",
      phone: "555-1234"
    )
    assert_not customer.valid?
    assert_includes customer.errors[:email], "is invalid"
  end

  test "should have first_name" do
    customer = Customer.new(
      last_name: "Doe",
      email: "john@example.com",
      phone: "555-1234"
    )
    assert_not customer.valid?
    assert_includes customer.errors[:first_name], "can't be blank"
  end

  test "should have last_name" do
    customer = Customer.new(
      first_name: "John",
      email: "john@example.com",
      phone: "555-1234"
    )
    assert_not customer.valid?
    assert_includes customer.errors[:last_name], "can't be blank"
  end

  test "should create valid customer" do
    customer = Customer.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )
    assert customer.valid?
  end

  test "should have many tickets" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )

    assert_respond_to customer, :tickets
  end

  test "should have full_name method" do
    customer = Customer.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )

    assert_equal "John Doe", customer.full_name
  end

  test "phone number is optional" do
    customer = Customer.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )
    assert customer.valid?
  end

  # Authentication tests
  test "should generate webauthn_id on create" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )
    assert customer.webauthn_id.present?
  end

  test "should downcase email" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "JOHN.DOE@EXAMPLE.COM"
    )
    assert_equal "john.doe@example.com", customer.email
  end

  test "should have unique email" do
    Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    duplicate = Customer.new(
      first_name: "Jane",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "should have unique webauthn_id" do
    customer1 = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    customer2 = Customer.new(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe@example.com"
    )
    customer2.webauthn_id = customer1.webauthn_id

    assert_not customer2.valid?
    assert_includes customer2.errors[:webauthn_id], "has already been taken"
  end




  test "should track confirmation status" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    assert_not customer.confirmed?

    customer.confirm!
    assert customer.confirmed?
    assert customer.email_confirmed_at.present?
    assert_nil customer.confirmation_token
  end

  test "should generate confirmation token" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    assert_nil customer.confirmation_token

    customer.generate_confirmation_token!
    assert customer.confirmation_token.present?
    assert customer.confirmation_sent_at.present?
  end




  test "should update sign in info" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    assert_equal 0, customer.sign_in_count
    assert_nil customer.last_sign_in_at

    customer.update_sign_in_info("192.168.1.1")

    assert_equal 1, customer.sign_in_count
    assert customer.last_sign_in_at.present?
    assert_equal "192.168.1.1", customer.last_sign_in_ip
  end

  test "should have many webauthn_credentials" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    assert_respond_to customer, :webauthn_credentials
  end

  test "should check if webauthn is enabled" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    assert_not customer.webauthn_enabled?

    customer.webauthn_credentials.create!(
      external_id: "test_id",
      public_key: Base64.strict_encode64("test_key"),
      sign_count: 0,
      name: "Test Key"
    )

    assert customer.webauthn_enabled?
  end

  test "should determine if credential can be deleted" do
    customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )

    credential = customer.webauthn_credentials.create!(
      external_id: "test_id",
      public_key: Base64.strict_encode64("test_key"),
      sign_count: 0,
      name: "Test Key"
    )

    # Can't delete if it's the only credential
    assert_not customer.can_delete_credential?(credential)

    # Can delete if there are multiple credentials
    customer.webauthn_credentials.create!(
      external_id: "test_id_2",
      public_key: Base64.strict_encode64("test_key_2"),
      sign_count: 0,
      name: "Test Key 2"
    )
    assert customer.can_delete_credential?(credential)
  end

  test "should have confirmed and unconfirmed scopes" do
    confirmed = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      email_confirmed_at: Time.current
    )

    unconfirmed = Customer.create!(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe@example.com"
    )

    assert_includes Customer.confirmed, confirmed
    assert_not_includes Customer.confirmed, unconfirmed

    assert_includes Customer.unconfirmed, unconfirmed
    assert_not_includes Customer.unconfirmed, confirmed
  end
end

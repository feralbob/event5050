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
end

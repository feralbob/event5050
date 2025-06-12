require "test_helper"

class TicketPurchaserTest < ActiveSupport::TestCase
  test "should have email" do
    purchaser = TicketPurchaser.new(
      first_name: "John",
      last_name: "Doe",
      phone: "555-1234"
    )
    assert_not purchaser.valid?
    assert_includes purchaser.errors[:email], "can't be blank"
  end

  test "should have valid email format" do
    purchaser = TicketPurchaser.new(
      first_name: "John",
      last_name: "Doe",
      email: "invalid.email",
      phone: "555-1234"
    )
    assert_not purchaser.valid?
    assert_includes purchaser.errors[:email], "is invalid"
  end

  test "should have first_name" do
    purchaser = TicketPurchaser.new(
      last_name: "Doe",
      email: "john@example.com",
      phone: "555-1234"
    )
    assert_not purchaser.valid?
    assert_includes purchaser.errors[:first_name], "can't be blank"
  end

  test "should have last_name" do
    purchaser = TicketPurchaser.new(
      first_name: "John",
      email: "john@example.com",
      phone: "555-1234"
    )
    assert_not purchaser.valid?
    assert_includes purchaser.errors[:last_name], "can't be blank"
  end

  test "should create valid purchaser" do
    purchaser = TicketPurchaser.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )
    assert purchaser.valid?
  end

  test "should have many tickets" do
    purchaser = TicketPurchaser.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )

    assert_respond_to purchaser, :tickets
  end

  test "should have full_name method" do
    purchaser = TicketPurchaser.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )

    assert_equal "John Doe", purchaser.full_name
  end

  test "phone number is optional" do
    purchaser = TicketPurchaser.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com"
    )
    assert purchaser.valid?
  end
end

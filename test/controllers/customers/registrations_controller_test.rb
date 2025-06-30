require "test_helper"

class Customers::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_customers_registration_path
    assert_response :success
  end

  test "should create customer with valid data" do
    assert_difference("Customer.count") do
      post customers_registrations_path, params: {
        customer: {
          first_name: "John",
          last_name: "Doe",
          email: "john.doe@example.com",
          phone: "555-1234"
        }
      }
    end

    customer = Customer.last
    assert_equal "john.doe@example.com", customer.email
    assert_equal "John", customer.first_name
    assert_equal "Doe", customer.last_name
    assert customer.confirmation_token.present?
    assert customer.confirmation_sent_at.present?
    assert_nil customer.email_confirmed_at

    assert_redirected_to pending_customers_registrations_path
  end

  test "should not create customer with invalid data" do
    assert_no_difference("Customer.count") do
      post customers_registrations_path, params: {
        customer: {
          first_name: "",
          last_name: "",
          email: "invalid-email",
          phone: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create customer with duplicate email" do
    existing = customers(:one)

    assert_no_difference("Customer.count") do
      post customers_registrations_path, params: {
        customer: {
          first_name: "Jane",
          last_name: "Smith",
          email: existing.email,
          phone: "555-5678"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show pending page" do
    get pending_customers_registrations_path
    assert_response :success
  end

  test "should redirect if already signed in" do
    customer = customers(:one)
    sign_in_as(customer)

    get new_customers_registration_path
    assert_redirected_to root_path
  end
end

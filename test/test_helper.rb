ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  # Customer authentication helpers
  def sign_in_as(customer)
    # For tests, simulate a signed-in customer by setting up the session
    # This approach works with Rails integration tests
    open_session do |sess|
      sess.get "/"
      sess.session[:customer_id] = customer.id if customer.confirmed?
    end

    # Also set it in the main test session
    get "/"
    @request.session[:customer_id] = customer.id if customer.confirmed?
  end

  def sign_out_customer
    get "/"
    @request.session.delete(:customer_id) if @request
  end
end

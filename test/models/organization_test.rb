require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "should have a valid factory" do
    organization = Organization.new(
      name: "Test Organization",
      description: "A test organization"
    )
    assert organization.valid?
  end

  test "should require a name" do
    organization = Organization.new(description: "Test description")
    assert_not organization.valid?
    assert_includes organization.errors[:name], "can't be blank"
  end

  test "should have many org_users" do
    assert_respond_to Organization.new, :org_users
  end

  test "should destroy associated org_users when destroyed" do
    skip "Will implement after OrgUser model is created"
  end

  test "name should have reasonable length" do
    organization = Organization.new(name: "a" * 256, description: "Test")
    assert_not organization.valid?
    assert_includes organization.errors[:name], "is too long (maximum is 255 characters)"
  end

  # Currency support tests
  test "should have currency attribute" do
    organization = Organization.new(name: "Test Org", currency: "USD")
    assert_equal "USD", organization.currency
  end

  test "should default currency to USD" do
    organization = Organization.new(name: "Test Org")
    assert_equal "USD", organization.currency
  end

  test "should validate currency is a valid ISO code" do
    organization = Organization.new(name: "Test Org", currency: "INVALID")
    assert_not organization.valid?
    assert_includes organization.errors[:currency], "is not a valid ISO 4217 currency code"
  end

  test "should accept valid ISO currency codes" do
    %w[USD EUR GBP CAD AUD JPY].each do |currency_code|
      organization = Organization.new(name: "Test Org #{currency_code}", currency: currency_code)
      assert organization.valid?, "Should accept #{currency_code} as valid currency"
    end
  end

  test "should handle nil currency gracefully" do
    organization = Organization.new(name: "Test Org")
    organization.currency = nil

    # Should default to USD
    assert_equal "USD", organization.currency
    # Currency is defaulted to USD
  end

  test "should persist currency to database" do
    organization = Organization.create!(name: "Test Org", currency: "GBP")
    organization.reload

    assert_equal "GBP", organization.currency
    # Persisted successfully
  end
end

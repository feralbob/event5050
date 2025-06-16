require "test_helper"

class RaffleTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @license = licenses(:one)
  end

  test "should belong to an organization" do
    raffle = Raffle.new(
      license: @license,
      name: "Test Raffle",
      description: "Test Description"
    )
    assert_not raffle.valid?
    assert_includes raffle.errors[:organization], "must exist"
  end

  test "should belong to a license" do
    raffle = Raffle.new(
      organization: @organization,
      name: "Test Raffle",
      description: "Test Description"
    )
    assert_not raffle.valid?
    assert_includes raffle.errors[:license], "must exist"
  end

  test "should have a name" do
    raffle = Raffle.new(
      organization: @organization,
      license: @license,
      description: "Test Description"
    )
    assert_not raffle.valid?
    assert_includes raffle.errors[:name], "can't be blank"
  end

  test "should validate tenant scoping" do
    # Create a raffle for organization one
    raffle1 = Raffle.create!(
      organization: @organization,
      license: @license,
      name: "Test Raffle",
      description: "Test Description"
    )

    # Create a second organization and its license
    org2 = organizations(:two)
    license2 = licenses(:two)

    # Should be able to create raffle with same name in different organization
    raffle2 = Raffle.new(
      organization: org2,
      license: license2,
      name: "Test Raffle",
      description: "Test Description"
    )

    assert raffle2.valid?
  end

  test "should track status" do
    raffle = Raffle.create!(
      organization: @organization,
      license: @license,
      name: "Test Raffle",
      description: "Test Description",
      status: "draft"
    )

    assert_equal "draft", raffle.status

    # Update status
    raffle.update!(status: "active")
    assert_equal "active", raffle.status
  end

  test "should use ice_cube for recurring raffles" do
    raffle = Raffle.create!(
      organization: @organization,
      license: @license,
      name: "Weekly Raffle",
      description: "Happens every Friday",
      recurring: true,
      recurrence_rule: "FREQ=WEEKLY;BYDAY=FR"
    )

    assert raffle.recurring?
    assert_not_nil raffle.recurrence_rule
  end

  # Currency inheritance tests
  test "should inherit currency from organization by default" do
    # Create a fresh organization with EUR currency
    org = Organization.create!(name: "EUR Org", currency: "EUR")
    license = License.create!(
      organization: org,
      jurisdiction: jurisdictions(:one),
      license_number: "EUR-LICENSE-123",
      issued_at: Date.today,
      expires_at: 1.year.from_now,
      license_type: :single
    )

    raffle = Raffle.new(
      organization: org,
      license: license,
      name: "Test Raffle"
    )

    # Debug: check what's happening
    assert_equal "EUR", org.currency, "Organization should have EUR currency"
    assert_equal org.id, raffle.organization_id, "Raffle should be associated with organization"
    assert_equal "EUR", raffle.currency, "Raffle should inherit EUR from organization"
  end

  test "should allow overriding organization currency" do
    @organization.update!(currency: "USD")
    raffle = Raffle.create!(
      organization: @organization,
      license: @license,
      name: "Test Raffle",
      currency: "CAD"
    )

    assert_equal "CAD", raffle.currency
    assert_equal "USD", @organization.currency
  end

  test "should validate currency is a valid ISO code" do
    raffle = Raffle.new(
      organization: @organization,
      license: @license,
      name: "Test Raffle",
      currency: "INVALID"
    )

    assert_not raffle.valid?
    assert_includes raffle.errors[:currency], "is not a valid ISO 4217 currency code"
  end

  test "should persist currency to database" do
    raffle = Raffle.create!(
      organization: @organization,
      license: @license,
      name: "Test Raffle",
      currency: "JPY"
    )

    raffle.reload
    assert_equal "JPY", raffle.currency
    # Currency persisted successfully
  end

  test "should handle nil currency by inheriting from organization" do
    @organization.update!(currency: "AUD")
    raffle = Raffle.new(
      organization: @organization,
      license: @license,
      name: "Test Raffle"
    )
    raffle.currency = nil

    assert_equal "AUD", raffle.currency
  end
end

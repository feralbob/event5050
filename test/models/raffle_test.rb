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

  test "should have ticket pricing tiers" do
    pricing = [
      { quantity: 1, price_cents: 500, currency: "USD" },
      { quantity: 3, price_cents: 1000, currency: "USD" },
      { quantity: 10, price_cents: 2500, currency: "USD" }
    ]
    
    raffle = Raffle.create!(
      organization: @organization,
      license: @license,
      name: "Test Raffle",
      description: "Test Description",
      ticket_pricing: pricing
    )
    
    raffle.reload
    assert_equal 3, raffle.ticket_pricing.length
    assert_equal 500, raffle.ticket_pricing[0]["price_cents"]
    assert_equal 3, raffle.ticket_pricing[1]["quantity"]
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
end
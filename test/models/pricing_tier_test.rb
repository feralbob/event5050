require "test_helper"

class PricingTierTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @raffle = raffles(:one)
    ActsAsTenant.current_tenant = @organization

    # Clean up any existing pricing tiers
    @raffle.pricing_tiers.destroy_all
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should require all mandatory fields" do
    pricing_tier = PricingTier.new
    assert_not pricing_tier.valid?

    assert_includes pricing_tier.errors[:raffle], "must exist"
    assert_includes pricing_tier.errors[:name], "can't be blank"
    assert_includes pricing_tier.errors[:code], "can't be blank"
    assert_includes pricing_tier.errors[:ticket_quantity], "can't be blank"
    assert_includes pricing_tier.errors[:total_price_cents], "can't be blank"
  end

  test "should validate ticket_quantity is positive" do
    pricing_tier = PricingTier.new(
      raffle: @raffle,
      name: "Test",
      code: "test",
      ticket_quantity: 0,
      total_price_cents: 100
    )

    assert_not pricing_tier.valid?
    assert_includes pricing_tier.errors[:ticket_quantity], "must be greater than 0"
  end

  test "should validate total_price_cents is positive" do
    pricing_tier = PricingTier.new(
      raffle: @raffle,
      name: "Test",
      code: "test",
      ticket_quantity: 1,
      total_price_cents: 0
    )

    assert_not pricing_tier.valid?
    assert_includes pricing_tier.errors[:total_price_cents], "must be greater than 0"
  end

  test "should enforce unique code per raffle" do
    PricingTier.create!(
      raffle: @raffle,
      name: "Single Ticket",
      code: "single",
      ticket_quantity: 1,
      total_price_cents: 500
    )

    duplicate = PricingTier.new(
      raffle: @raffle,
      name: "Another Single",
      code: "single",
      ticket_quantity: 1,
      total_price_cents: 600
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "should allow same code for different raffles" do
    another_raffle = Raffle.create!(
      organization: @organization,
      license: licenses(:one),
      name: "Another Raffle"
    )

    tier1 = PricingTier.create!(
      raffle: @raffle,
      name: "Single Ticket",
      code: "single",
      ticket_quantity: 1,
      total_price_cents: 500
    )

    tier2 = PricingTier.new(
      raffle: another_raffle,
      name: "Single Ticket",
      code: "single",
      ticket_quantity: 1,
      total_price_cents: 600
    )

    assert tier2.valid?
  end

  test "should calculate price per ticket" do
    pricing_tier = PricingTier.new(
      ticket_quantity: 3,
      total_price_cents: 1000
    )

    assert_equal 333, pricing_tier.price_per_ticket_cents
  end

  test "should calculate savings amount" do
    single_tier = PricingTier.new(
      ticket_quantity: 1,
      total_price_cents: 500
    )

    bundle_tier = PricingTier.new(
      ticket_quantity: 3,
      total_price_cents: 1000
    )

    assert_equal 500, bundle_tier.savings_cents(single_tier)
  end

  test "should have active scope" do
    active_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Active",
      code: "active",
      ticket_quantity: 1,
      total_price_cents: 500,
      active: true
    )

    inactive_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Inactive",
      code: "inactive",
      ticket_quantity: 1,
      total_price_cents: 500,
      active: false
    )

    assert_includes PricingTier.active, active_tier
    assert_not_includes PricingTier.active, inactive_tier
  end

  test "should order by display_order" do
    tier3 = PricingTier.create!(
      raffle: @raffle,
      name: "Third",
      code: "third",
      ticket_quantity: 10,
      total_price_cents: 2500,
      display_order: 3
    )

    tier1 = PricingTier.create!(
      raffle: @raffle,
      name: "First",
      code: "first",
      ticket_quantity: 1,
      total_price_cents: 500,
      display_order: 1
    )

    tier2 = PricingTier.create!(
      raffle: @raffle,
      name: "Second",
      code: "second",
      ticket_quantity: 3,
      total_price_cents: 1000,
      display_order: 2
    )

    ordered = PricingTier.ordered
    assert_equal [ tier1, tier2, tier3 ], ordered.to_a
  end

  test "should format display text" do
    pricing_tier = PricingTier.new(
      name: "3 Ticket Bundle",
      ticket_quantity: 3,
      total_price_cents: 1000,
      description: "Save $5!"
    )

    assert_equal "3 Ticket Bundle - $10.00", pricing_tier.display_text
    assert_equal "3 Ticket Bundle - $10.00 (Save $5!)", pricing_tier.display_text_with_description
  end

  # Money gem integration tests
  test "should monetize total_price_cents field" do
    pricing_tier = PricingTier.new(
      raffle: @raffle,
      name: "Test",
      code: "test",
      ticket_quantity: 1,
      total_price_cents: 500
    )

    assert_respond_to pricing_tier, :total_price
    assert_instance_of Money, pricing_tier.total_price
    assert_equal Money.new(500, "USD"), pricing_tier.total_price
  end

  test "should validate positive money amounts using Money gem" do
    pricing_tier = PricingTier.new(
      raffle: @raffle,
      name: "Test",
      code: "test",
      ticket_quantity: 1,
      total_price: Money.new(-100, "USD")
    )

    assert_not pricing_tier.valid?
    assert_includes pricing_tier.errors[:total_price], "must be greater than 0"
  end

  test "should calculate price per ticket using Money operations" do
    pricing_tier = PricingTier.new(
      ticket_quantity: 3,
      total_price: Money.new(1500, "USD")
    )

    assert_equal Money.new(500, "USD"), pricing_tier.price_per_ticket
  end

  test "should calculate savings between tiers with Money precision" do
    single_tier = PricingTier.new(
      ticket_quantity: 1,
      total_price: Money.new(500, "USD")
    )

    bundle_tier = PricingTier.new(
      ticket_quantity: 3,
      total_price: Money.new(1200, "USD")
    )

    expected_savings = Money.new(300, "USD") # 3 * $5.00 - $12.00 = $3.00
    assert_equal expected_savings, bundle_tier.savings(single_tier)
  end

  test "should format prices using Money gem formatting" do
    pricing_tier = PricingTier.new(
      name: "Test Bundle",
      total_price: Money.new(1234, "USD")
    )

    assert_equal "$12.34", pricing_tier.formatted_price
  end

  test "should handle currency conversions for multi-currency support" do
    pricing_tier = PricingTier.new(
      raffle: @raffle,
      name: "Euro Test",
      code: "euro",
      ticket_quantity: 1,
      total_price: Money.new(1000, "EUR")
    )

    assert_equal "EUR", pricing_tier.total_price.currency.to_s
    assert_equal Money.new(1000, "EUR"), pricing_tier.total_price
  end

  # Currency inheritance tests
  test "should inherit currency from raffle by default" do
    @raffle.update!(currency: "CAD")
    pricing_tier = PricingTier.new(
      raffle: @raffle,
      name: "Test Tier",
      code: "test",
      ticket_quantity: 1,
      total_price_cents: 500
    )

    assert_equal "CAD", pricing_tier.currency
  end

  test "should allow overriding raffle currency" do
    @raffle.update!(currency: "USD")
    pricing_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Test Tier",
      code: "test",
      ticket_quantity: 1,
      total_price_cents: 500,
      currency: "EUR"
    )

    assert_equal "EUR", pricing_tier.currency
    assert_equal "USD", @raffle.currency
  end

  test "should use consistent currency for money calculations" do
    @raffle.update!(currency: "JPY")
    pricing_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Test Tier",
      code: "test",
      ticket_quantity: 3,
      total_price_cents: 1500
    )

    assert_equal "JPY", pricing_tier.total_price.currency.to_s
    assert_equal "JPY", pricing_tier.price_per_ticket.currency.to_s
    assert_equal Money.new(500, "JPY"), pricing_tier.price_per_ticket
  end

  test "should inherit currency through chain: Organization -> Raffle -> PricingTier" do
    # Create organization with AUD currency
    org = Organization.create!(name: "Australian Org", currency: "AUD")

    # Set the tenant for acts_as_tenant
    ActsAsTenant.with_tenant(org) do
      license = License.create!(
        organization: org,
        jurisdiction: jurisdictions(:one),
        license_number: "AUD-LICENSE-123",
        issued_at: Date.today,
        expires_at: 1.year.from_now,
        license_type: :single
      )
      raffle = Raffle.create!(
        organization: org,
        license: license,
        name: "AUD Raffle"
      )

      # Verify raffle inherited the currency
      assert_equal "AUD", raffle.currency

      pricing_tier = PricingTier.new(
        raffle: raffle,
        name: "Test Tier",
        code: "test",
        ticket_quantity: 1,
        total_price_cents: 1000
      )

      assert_equal "AUD", pricing_tier.currency
      # Currency inherited correctly
    end
  end

  test "should calculate savings with same currency" do
    @raffle.update!(currency: "EUR")

    single_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Single",
      code: "single",
      ticket_quantity: 1,
      total_price_cents: 500
    )

    bundle_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Bundle",
      code: "bundle",
      ticket_quantity: 3,
      total_price_cents: 1200
    )

    savings = bundle_tier.savings(single_tier)
    assert_equal Money.new(300, "EUR"), savings
    assert_equal "EUR", savings.currency.to_s
  end
end

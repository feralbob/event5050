require "test_helper"

class TicketPurchaseTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @raffle = raffles(:one)
    @draw = draws(:one)
    @customer = customers(:one)

    ActsAsTenant.current_tenant = @organization

    @pricing_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Bundle Deal",
      code: "bundle",
      ticket_quantity: 3,
      total_price_cents: 1000,
      currency: "USD"
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should be valid with valid attributes" do
    ticket_purchase = TicketPurchase.new(
      draw: @draw,
      customer: @customer,
      pricing_tier: @pricing_tier,
      total_amount_cents: 1000,
      currency: "USD",
      purchase_date: Time.current
    )
    assert ticket_purchase.valid?
  end

  test "should require total_amount_cents" do
    ticket_purchase = TicketPurchase.new(
      draw: @draw,
      customer: @customer,
      pricing_tier: @pricing_tier,
      currency: "USD",
      purchase_date: Time.current
    )
    assert_not ticket_purchase.valid?
    assert_includes ticket_purchase.errors[:total_amount_cents], "can't be blank"
  end

  test "should monetize total_amount" do
    ticket_purchase = TicketPurchase.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: @pricing_tier,
      total_amount_cents: 1000,
      currency: "USD",
      purchase_date: Time.current
    )

    assert_equal Money.new(1000, "USD"), ticket_purchase.total_amount
    assert_equal "$10.00", ticket_purchase.formatted_amount
  end

  test "should return ticket count from pricing tier" do
    ticket_purchase = TicketPurchase.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: @pricing_tier,
      total_amount_cents: 1000,
      currency: "USD",
      purchase_date: Time.current
    )

    assert_equal 3, ticket_purchase.ticket_count
  end

  test "should have default metadata and purchase_date" do
    ticket_purchase = TicketPurchase.new(
      draw: @draw,
      customer: @customer,
      pricing_tier: @pricing_tier,
      total_amount_cents: 1000,
      currency: "USD"
    )

    assert_equal({}, ticket_purchase.metadata)
    assert_not_nil ticket_purchase.purchase_date
  end
end

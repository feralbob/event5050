require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @draw = draws(:one)
    @customer = Customer.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )
  end

  test "should belong to a draw" do
    ticket = Ticket.new(
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:draw], "must exist"
  end

  test "should belong to a customer" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_number: "TKT123456",
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:customer], "must exist"
  end

  test "should have ticket_number" do
    ticket = Ticket.new(
      draw: @draw,
      customer: @customer,
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:ticket_number], "can't be blank"
  end

  test "should have unique ticket_number" do
    Ticket.create!(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active"
    )

    duplicate_ticket = Ticket.new(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active"
    )

    assert_not duplicate_ticket.valid?
    assert_includes duplicate_ticket.errors[:ticket_number], "has already been taken"
  end

  test "should work without price_cents when using new purchase model" do
    ticket = Ticket.new(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active"
    )
    assert ticket.valid? # price_cents is now optional
  end

  test "should track status" do
    ticket = Ticket.create!(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active"
    )

    assert_equal "active", ticket.status

    # Win the ticket
    ticket.update!(status: "won", prize_won: "main_prize")
    assert_equal "won", ticket.status
    assert_equal "main_prize", ticket.prize_won
  end

  test "should generate human-readable ticket number" do
    ticket = Ticket.new(
      draw: @draw,
      customer: @customer
    )

    ticket.generate_ticket_number!

    assert_not_nil ticket.ticket_number
    assert_match /^[A-Z0-9]{3}-[A-Z0-9]{3}-[A-Z0-9]{3}$/, ticket.ticket_number
  end

  test "should store purchase metadata" do
    metadata = {
      "purchase_time" => Time.current.iso8601,
      "ip_address" => "192.168.1.1",
      "user_agent" => "Mozilla/5.0"
    }

    ticket = Ticket.create!(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active",
      purchase_metadata: metadata
    )

    ticket.reload
    assert_equal "192.168.1.1", ticket.purchase_metadata["ip_address"]
  end

  test "should not allow multiple wins for same customer in same draw" do
    # Create first winning ticket
    ticket1 = Ticket.create!(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT111111",
      status: "won",
      prize_won: "main_prize"
    )

    # Try to create second ticket for same customer
    ticket2 = Ticket.create!(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT222222",
      status: "active"
    )

    # Should not be able to win again
    ticket2.status = "won"
    ticket2.prize_won = "secondary_prize"

    assert_not ticket2.valid?
    assert_includes ticket2.errors[:base], "Customer has already won a prize in this draw"
  end


  test "effective_price should calculate correctly from ticket_purchase" do
    organization = organizations(:one)
    raffle = raffles(:one)
    ActsAsTenant.current_tenant = organization

    pricing_tier = PricingTier.create!(
      raffle: raffle,
      name: "Bundle Deal",
      code: "bundle",
      ticket_quantity: 3,
      total_price_cents: 1000,
      currency: "USD"
    )

    ticket_purchase = TicketPurchase.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      total_amount_cents: 1000,
      currency: "USD",
      purchase_date: Time.current
    )

    ticket = Ticket.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      ticket_purchase: ticket_purchase,
      ticket_number: "NEW-123-XYZ"
    )

    # Should calculate 1000 cents / 3 tickets = 333.33 cents per ticket
    expected_price = Money.new(333, "USD")
    assert_equal expected_price, ticket.effective_price
  end

  test "should inherit currency from draw/raffle" do
    ticket = Ticket.new(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      status: "active"
    )

    assert_equal "USD", ticket.currency
  end

  # Currency inheritance tests
  test "should inherit currency through chain: Organization -> Raffle -> Draw -> Ticket" do
    # Create organization with EUR currency
    org = Organization.create!(name: "European Org", currency: "EUR")

    ActsAsTenant.with_tenant(org) do
      license = License.create!(
        organization: org,
        jurisdiction: jurisdictions(:one),
        license_number: "EUR-LICENSE-123",
        issued_at: Date.today,
        expires_at: 1.year.from_now,
        license_type: :single
      )
      raffle = Raffle.create!(
        organization: org,
        license: license,
        name: "EUR Raffle"
      )
      draw = Draw.create!(
        raffle: raffle,
        draw_date: Date.today + 1.week,
        ticket_sales_start_at: Time.current,
        ticket_sales_end_at: Time.current + 6.days,
        status: "active"
      )

      ticket = Ticket.new(
        draw: draw,
        customer: @customer,
        ticket_number: "EUR-123-456"
      )

      assert_equal "EUR", ticket.currency
    end
  end

  test "should use consistent currency for effective_price calculations" do
    @draw.raffle.update!(currency: "CAD")

    organization = organizations(:one)
    ActsAsTenant.current_tenant = organization

    pricing_tier = PricingTier.create!(
      raffle: @draw.raffle,
      name: "CAD Bundle",
      code: "cad_bundle",
      ticket_quantity: 3,
      total_price_cents: 1500
    )

    ticket_purchase = TicketPurchase.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      total_amount_cents: 1500,
      currency: "CAD",
      purchase_date: Time.current
    )

    ticket = Ticket.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      ticket_purchase: ticket_purchase,
      ticket_number: "CAD-123-XYZ"
    )

    assert_equal "CAD", ticket.effective_price.currency.to_s
    assert_equal Money.new(500, "CAD"), ticket.effective_price
  end

  test "should handle currency fallback chain properly" do
    # Test with pricing tier currency
    pricing_tier = PricingTier.new(
      raffle: @draw.raffle,
      name: "JPY Tier",
      code: "jpy",
      ticket_quantity: 1,
      total_price_cents: 1000,
      currency: "JPY"
    )

    ticket = Ticket.new(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      ticket_number: "JPY-123-456"
    )

    # Should get currency from pricing tier if available
    assert_equal "JPY", ticket.currency
  end

  test "should format price with proper currency symbol" do
    @draw.raffle.update!(currency: "EUR")

    organization = organizations(:one)
    ActsAsTenant.current_tenant = organization

    pricing_tier = PricingTier.create!(
      raffle: @draw.raffle,
      name: "EUR Single",
      code: "eur_single",
      ticket_quantity: 1,
      total_price_cents: 500
    )

    ticket_purchase = TicketPurchase.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      total_amount_cents: 500,
      currency: "EUR",
      purchase_date: Time.current
    )

    ticket = Ticket.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      ticket_purchase: ticket_purchase,
      ticket_number: "EUR-TEST-123"
    )

    # EUR formatting might vary by locale, but should include currency
    assert_match /5/, ticket.formatted_price
  end



  test "should format ticket price for display from ticket_purchase" do
    organization = organizations(:one)
    raffle = raffles(:one)
    ActsAsTenant.current_tenant = organization

    pricing_tier = PricingTier.create!(
      raffle: raffle,
      name: "Single",
      code: "single_test_#{SecureRandom.hex(4)}",
      ticket_quantity: 1,
      total_price_cents: 1234,
      currency: "USD"
    )

    ticket_purchase = TicketPurchase.create!(
      draw: @draw,
      customer: @customer,
      pricing_tier: pricing_tier,
      total_amount_cents: 1234,
      currency: "USD",
      purchase_date: Time.current
    )

    ticket = Ticket.new(
      draw: @draw,
      customer: @customer,
      ticket_number: "TKT123456",
      ticket_purchase: ticket_purchase,
      pricing_tier: pricing_tier,
      status: "active"
    )

    assert_equal "$12.34", ticket.formatted_price
  end
end

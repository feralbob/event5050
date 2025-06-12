require "test_helper"

class PricingRoundingFixTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @raffle = raffles(:one)
    @draw = draws(:one)
    @draw.update!(total_revenue_cents: 0)

    ActsAsTenant.current_tenant = @organization

    @raffle.pricing_tiers.destroy_all

    # Create problematic pricing tier: $10 for 3 tickets = $3.33 per ticket
    @bundle_tier = PricingTier.create!(
      raffle: @raffle,
      name: "3 Ticket Bundle",
      code: "bundle_3",
      ticket_quantity: 3,
      total_price_cents: 1000, # $10.00
      display_order: 1
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should fix rounding errors in ticket pricing" do
    # Purchase 3 tickets for $10 using the bundle tier
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @bundle_tier,
      purchaser_attributes: {
        first_name: "Jane",
        last_name: "Smith",
        email: "jane@example.com",
        phone: "555-5678"
      }
    )

    result = service.purchase!
    assert result.success?, "Purchase should succeed"

    # Verify we get exactly 3 tickets
    assert_equal 3, result.tickets.count

    # Verify the ticket purchase has the exact amount paid
    assert_equal 1000, result.ticket_purchase.total_amount_cents
    assert_equal "$10.00", result.ticket_purchase.formatted_amount

    # Verify individual tickets are linked to the purchase
    result.tickets.each do |ticket|
      assert_equal result.ticket_purchase, ticket.ticket_purchase
      assert_equal @bundle_tier, ticket.pricing_tier
    end

    # Verify draw revenue is exactly what was paid (no rounding loss)
    @draw.reload
    assert_equal 1000, @draw.total_revenue_cents, "Draw revenue should be exactly $10.00"

    # Make another purchase to verify accumulation works correctly
    service2 = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @bundle_tier,
      purchaser_attributes: {
        first_name: "Bob",
        last_name: "Johnson",
        email: "bob@example.com",
        phone: "555-9999"
      }
    )

    result2 = service2.purchase!
    assert result2.success?, "Second purchase should succeed"

    # Verify total revenue is exactly $20.00 (no cumulative rounding errors)
    @draw.reload
    assert_equal 2000, @draw.total_revenue_cents, "Draw revenue should be exactly $20.00"

    # Verify we have 2 separate purchases
    assert_equal 2, @draw.ticket_purchases.count

    # Count tickets created by our purchases (excluding any fixture tickets)
    our_tickets = @draw.tickets.joins(:ticket_purchase)
    assert_equal 6, our_tickets.count # 3 tickets per purchase

    # Verify each purchase maintains its exact amount
    @draw.ticket_purchases.each do |purchase|
      assert_equal 1000, purchase.total_amount_cents
      assert_equal 3, purchase.tickets.count
    end
  end

  test "should demonstrate old vs new approach" do
    # Simulate old approach calculation
    old_price_per_ticket_cents = @bundle_tier.total_price_cents / @bundle_tier.ticket_quantity
    old_total_for_3_tickets = old_price_per_ticket_cents * 3
    rounding_loss = @bundle_tier.total_price_cents - old_total_for_3_tickets

    assert_equal 333, old_price_per_ticket_cents, "Old approach: $3.33 per ticket"
    assert_equal 999, old_total_for_3_tickets, "Old approach: 3 * $3.33 = $9.99"
    assert_equal 1, rounding_loss, "Old approach loses 1 cent due to rounding"

    # New approach
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @bundle_tier,
      purchaser_attributes: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        phone: "555-1234"
      }
    )

    result = service.purchase!

    # New approach maintains exact pricing
    assert_equal 1000, result.ticket_purchase.total_amount_cents, "New approach: exactly $10.00"
    assert_equal 1000, @draw.reload.total_revenue_cents, "New approach: no revenue loss"

    # Individual ticket effective price is calculated dynamically
    ticket = result.tickets.first
    effective_price = ticket.effective_price
    assert_equal Money.new(333, "USD"), effective_price, "Effective price per ticket: $3.33"

    # But total is always correct
    total_effective = result.tickets.sum { |t| t.effective_price.cents }
    assert_equal 999, total_effective, "Sum of effective prices: $9.99"

    # The difference is maintained at the purchase level
    purchase_total = result.ticket_purchase.total_amount_cents
    assert_equal 1000, purchase_total, "Purchase total: exactly $10.00"

    puts "\n=== Pricing Rounding Fix Demonstration ==="
    puts "Old approach:"
    puts "  $10.00 ÷ 3 tickets = $3.33 per ticket"
    puts "  3 tickets × $3.33 = $9.99 (loses $0.01)"
    puts "New approach:"
    puts "  Purchase tracked at $10.00 exact"
    puts "  Individual tickets reference purchase"
    puts "  Revenue calculation: exactly $10.00"
    puts "  No rounding errors!"
  end
end

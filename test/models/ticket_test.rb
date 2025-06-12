require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @draw = draws(:one)
    @purchaser = TicketPurchaser.create!(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-1234"
    )
  end

  test "should belong to a draw" do
    ticket = Ticket.new(
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:draw], "must exist"
  end

  test "should belong to a ticket_purchaser" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:ticket_purchaser], "must exist"
  end

  test "should have ticket_number" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      price_cents: 500,
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:ticket_number], "can't be blank"
  end

  test "should have unique ticket_number" do
    Ticket.create!(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active"
    )
    
    duplicate_ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active"
    )
    
    assert_not duplicate_ticket.valid?
    assert_includes duplicate_ticket.errors[:ticket_number], "has already been taken"
  end

  test "should have price_cents" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      status: "active"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:price_cents], "can't be blank"
  end

  test "should track status" do
    ticket = Ticket.create!(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
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
      ticket_purchaser: @purchaser,
      price_cents: 500
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
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active",
      purchase_metadata: metadata
    )
    
    ticket.reload
    assert_equal "192.168.1.1", ticket.purchase_metadata["ip_address"]
  end

  test "should not allow multiple wins for same purchaser in same draw" do
    # Create first winning ticket
    ticket1 = Ticket.create!(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT111111",
      price_cents: 500,
      status: "won",
      prize_won: "main_prize"
    )
    
    # Try to create second ticket for same purchaser
    ticket2 = Ticket.create!(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT222222",
      price_cents: 500,
      status: "active"
    )
    
    # Should not be able to win again
    ticket2.status = "won"
    ticket2.prize_won = "secondary_prize"
    
    assert_not ticket2.valid?
    assert_includes ticket2.errors[:base], "Purchaser has already won a prize in this draw"
  end

  # Money gem integration tests
  test "should monetize price_cents field" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active"
    )
    
    assert_respond_to ticket, :price
    assert_instance_of Money, ticket.price
    assert_equal Money.new(500, "USD"), ticket.price
  end

  test "should validate ticket price is positive" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price: Money.new(-100, "USD"),
      status: "active"
    )
    
    assert_not ticket.valid?
    assert_includes ticket.errors[:price], "must be greater than 0"
  end

  test "should inherit currency from draw/raffle" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price_cents: 500,
      status: "active"
    )
    
    assert_equal "USD", ticket.currency
    assert_equal "USD", ticket.price.currency.to_s
  end

  test "should calculate refund amounts accurately" do
    ticket = Ticket.create!(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price: Money.new(750, "USD"),
      status: "active"
    )
    
    # Calculate refund amount (could be partial)
    refund_amount = ticket.price * 0.95 # 95% refund
    expected_refund = Money.new(713, "USD") # 95% of $7.50 = $7.13 (rounded)
    
    assert_equal expected_refund, refund_amount.round
  end

  test "should support multi-currency pricing" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price: Money.new(500, "EUR"),
      status: "active"
    )
    
    assert_equal "EUR", ticket.price.currency.to_s
    assert_equal Money.new(500, "EUR"), ticket.price
  end

  test "should format ticket price for display" do
    ticket = Ticket.new(
      draw: @draw,
      ticket_purchaser: @purchaser,
      ticket_number: "TKT123456",
      price: Money.new(1234, "USD"),
      status: "active"
    )
    
    assert_equal "$12.34", ticket.formatted_price
  end
end
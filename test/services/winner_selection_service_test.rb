require "test_helper"

class WinnerSelectionServiceTest < ActiveSupport::TestCase
  setup do
    @draw = draws(:one)
    @draw.update!(status: :closed)
    @service = WinnerSelectionService.new(@draw)

    # Create test tickets
    @tickets = []
    5.times do |i|
      purchaser = TicketPurchaser.create!(
        first_name: "Test#{i}",
        last_name: "User#{i}",
        email: "test#{i}@example.com",
        phone: "555-000#{i}"
      )

      ticket = @draw.tickets.build(
        ticket_purchaser: purchaser,
        status: :active
      )
      ticket.generate_ticket_number!
      ticket.save!
      @tickets << ticket
    end
  end

  test "should select winner for main prize" do
    result = @service.select_winner("main_prize")

    assert result.success?
    winning_ticket = result.winner
    assert_not_nil winning_ticket
    assert @tickets.include?(winning_ticket)
    assert_equal "won", winning_ticket.status
    assert_equal "main_prize", winning_ticket.prize_won
  end

  test "should not select same winner twice" do
    # First winner
    result1 = @service.select_winner("main_prize")
    winner1 = result1.winner

    # Try to select second winner for different prize
    result2 = @service.select_winner("second_prize")
    winner2 = result2.winner

    assert_not_equal winner1, winner2
    assert_not_equal winner1.ticket_purchaser, winner2.ticket_purchaser
  end

  test "should handle no eligible tickets" do
    # Create a different draw with all won tickets
    other_draw = Draw.create!(
      raffle: @draw.raffle,
      draw_date: Date.today + 2.weeks,
      ticket_sales_start_at: 1.hour.ago,
      ticket_sales_end_at: 1.hour.from_now,
      status: :closed
    )

    # Create tickets that are all won by different purchasers
    5.times do |i|
      purchaser = TicketPurchaser.create!(
        first_name: "Winner#{i}",
        last_name: "Test#{i}",
        email: "winner#{i}@example.com",
        phone: "555-100#{i}"
      )

      ticket = other_draw.tickets.build(
        ticket_purchaser: purchaser,
        status: :won,
        prize_won: "prize_#{i}"
      )
      ticket.generate_ticket_number!
      ticket.save!
    end

    service = WinnerSelectionService.new(other_draw)
    result = service.select_winner("consolation_prize")

    assert_equal false, result.success?
    assert_equal "No eligible tickets available", result.error
  end

  test "should only select from active tickets" do
    # Mark some tickets as refunded
    @tickets.first(3).each { |t| t.update!(status: :refunded) }

    result = @service.select_winner("main_prize")

    assert result.success?
    assert @tickets.last(2).include?(result.winner)
  end

  test "should not select winner if draw not closed" do
    @draw.update!(status: :active)

    result = @service.select_winner("main_prize")

    assert_equal false, result.success?
    assert_equal "Draw must be closed before selecting winners", result.error
  end

  test "should mark draw as drawn after all prizes selected" do
    @draw.update!(prize_pool: {
      "main_prize_cents" => 1000,
      "prizes" => [ "main_prize" ]
    })

    @service.select_winner("main_prize")
    @service.finalize_draw!

    assert_equal "drawn", @draw.reload.status
  end
end

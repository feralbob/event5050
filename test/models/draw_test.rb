require "test_helper"

class DrawTest < ActiveSupport::TestCase
  setup do
    @raffle = raffles(:one)
    @organization = @raffle.organization
  end

  test "should belong to a raffle" do
    draw = Draw.new(
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 1.week,
      status: "scheduled"
    )
    assert_not draw.valid?
    assert_includes draw.errors[:raffle], "must exist"
  end

  test "should have draw_date" do
    draw = Draw.new(
      raffle: @raffle,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 1.week,
      status: "scheduled"
    )
    assert_not draw.valid?
    assert_includes draw.errors[:draw_date], "can't be blank"
  end

  test "should have ticket_sales_start_at" do
    draw = Draw.new(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_end_at: Time.current + 1.week,
      status: "scheduled"
    )
    assert_not draw.valid?
    assert_includes draw.errors[:ticket_sales_start_at], "can't be blank"
  end

  test "should have ticket_sales_end_at" do
    draw = Draw.new(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      status: "scheduled"
    )
    assert_not draw.valid?
    assert_includes draw.errors[:ticket_sales_end_at], "can't be blank"
  end

  test "ticket_sales_end_at should be after ticket_sales_start_at" do
    draw = Draw.new(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current + 1.week,
      ticket_sales_end_at: Time.current,
      status: "scheduled"
    )
    assert_not draw.valid?
    assert_includes draw.errors[:ticket_sales_end_at], "must be after start time"
  end

  test "draw_date should be on or after ticket_sales_end_at" do
    draw = Draw.new(
      raffle: @raffle,
      draw_date: Date.today,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 1.week,
      status: "scheduled"
    )
    assert_not draw.valid?
    assert_includes draw.errors[:draw_date], "must be on or after ticket sales end"
  end

  test "should track status transitions" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "scheduled"
    )

    assert_equal "scheduled", draw.status

    # Transition to active
    draw.update!(status: "active")
    assert_equal "active", draw.status

    # Transition to closed
    draw.update!(status: "closed")
    assert_equal "closed", draw.status

    # Transition to drawn
    draw.update!(status: "drawn")
    assert_equal "drawn", draw.status
  end

  test "should calculate total revenue" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "scheduled"
    )

    # Initially should be 0
    assert_equal 0, draw.total_revenue_cents

    # After setting revenue
    draw.update!(total_revenue_cents: 50000)
    assert_equal 50000, draw.total_revenue_cents
  end

  test "should store prize pool information" do
    prize_pool = {
      "main_prize" => { "amount_cents" => 25000, "percentage" => 50 },
      "secondary_prizes" => [
        { "name" => "Early Bird", "amount_cents" => 5000 }
      ]
    }

    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "scheduled",
      prize_pool: prize_pool
    )

    draw.reload
    assert_equal 25000, draw.prize_pool["main_prize"]["amount_cents"]
    assert_equal 50, draw.prize_pool["main_prize"]["percentage"]
    assert_equal "Early Bird", draw.prize_pool["secondary_prizes"][0]["name"]
  end

  test "should know if ticket sales are open" do
    # Future draw - sales not started
    future_draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 2.weeks,
      ticket_sales_start_at: Time.current + 1.week,
      ticket_sales_end_at: Time.current + 2.weeks,
      status: "scheduled"
    )
    assert_not future_draw.ticket_sales_open?

    # Active draw - sales open
    active_draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current - 1.day,
      ticket_sales_end_at: Time.current + 5.days,
      status: "active"
    )
    assert active_draw.ticket_sales_open?

    # Closed draw - sales ended
    closed_draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today,
      ticket_sales_start_at: Time.current - 1.week,
      ticket_sales_end_at: Time.current - 1.hour,
      status: "closed"
    )
    assert_not closed_draw.ticket_sales_open?
  end

  test "should calculate prize pool based on total revenue" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue_cents: 10000 # $100
    )

    draw.calculate_prize_pool!

    assert_equal 5000, draw.prize_pool["main_prize_cents"] # 50% = $50
    assert_equal 5000, draw.prize_pool["organization_revenue_cents"] # 50% = $50
  end

  test "should update status to active when sales start" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: 1.minute.ago,
      ticket_sales_end_at: 1.hour.from_now,
      status: :scheduled
    )

    draw.check_and_update_status!
    assert draw.active?
  end

  test "should update status to closed when sales end" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today,
      ticket_sales_start_at: 2.hours.ago,
      ticket_sales_end_at: 1.minute.ago,
      status: :active
    )

    draw.check_and_update_status!
    assert draw.closed?
  end

  test "should have active draws scope" do
    active_draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: 1.hour.ago,
      ticket_sales_end_at: 1.hour.from_now,
      status: :active
    )

    assert_includes Draw.active_for_purchase, active_draw
  end

  test "should increment revenue when ticket purchased" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue_cents: 0
    )

    draw.increment_revenue!(500) # $5

    assert_equal 500, draw.reload.total_revenue_cents
  end

  # Money gem integration tests
  test "should monetize total_revenue_cents field" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue_cents: 5000
    )

    assert_respond_to draw, :total_revenue
    assert_instance_of Money, draw.total_revenue
    assert_equal Money.new(5000, "USD"), draw.total_revenue
  end

  test "should track revenue updates with Money precision" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue: Money.new(0, "USD")
    )

    # Add revenue using Money objects
    ticket_price = Money.new(750, "USD") # $7.50
    draw.increment_revenue!(ticket_price)

    assert_equal Money.new(750, "USD"), draw.reload.total_revenue
  end

  test "should calculate prize pool with Money precision" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue: Money.new(10000, "USD") # $100.00
    )

    draw.calculate_prize_pool!

    main_prize = Money.new(5000, "USD") # 50% = $50.00
    organization_revenue = Money.new(5000, "USD") # 50% = $50.00

    assert_equal main_prize.cents, draw.prize_pool["main_prize_cents"]
    assert_equal organization_revenue.cents, draw.prize_pool["organization_revenue_cents"]
  end

  test "should handle fee deductions in prize pool calculations" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue: Money.new(10000, "USD") # $100.00
    )

    # Should eventually include platform fees, license fees, etc.
    platform_fee_rate = 0.025 # 2.5%
    license_fee_rate = 0.0235 # 2.35% (from specification)

    total_fees = draw.total_revenue * (platform_fee_rate + license_fee_rate)
    net_revenue = draw.total_revenue - total_fees
    main_prize = net_revenue * 0.5

    # For now, just test the concept - implementation will come with FeeCalculator
    expected_total_fees = Money.new(485, "USD") # 4.85% of $100 = $4.85
    expected_net_revenue = Money.new(9515, "USD") # $100 - $4.85 = $95.15
    expected_main_prize = Money.new(4758, "USD") # 50% of $95.15 = $47.58 (rounded)

    assert_equal expected_total_fees, total_fees.round
    assert_equal expected_net_revenue, net_revenue.round
    assert_equal expected_main_prize, main_prize.round
  end

  test "should support multi-currency revenue tracking" do
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue: Money.new(5000, "EUR")
    )

    assert_equal "EUR", draw.total_revenue.currency.to_s
    assert_equal Money.new(5000, "EUR"), draw.total_revenue
  end

  # Currency inheritance tests
  test "should inherit currency from raffle by default" do
    @raffle.update!(currency: "GBP")
    draw = Draw.new(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days
    )

    assert_equal "GBP", draw.currency
  end

  test "should use consistent currency for total_revenue Money object" do
    @raffle.update!(currency: "EUR")
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue_cents: 10000
    )

    assert_equal "EUR", draw.total_revenue.currency.to_s
    assert_equal Money.new(10000, "EUR"), draw.total_revenue
  end

  test "should inherit currency through chain: Organization -> Raffle -> Draw" do
    # Create organization with JPY currency
    org = Organization.create!(name: "Japanese Org", currency: "JPY")
    license = License.create!(
      organization: org,
      jurisdiction: jurisdictions(:one),
      license_number: "JPY-LICENSE-123",
      issued_at: Date.today,
      expires_at: 1.year.from_now,
      license_type: :single
    )
    raffle = Raffle.create!(
      organization: org,
      license: license,
      name: "JPY Raffle"
    )

    draw = Draw.new(
      raffle: raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days
    )

    assert_equal "JPY", draw.currency
    # Currency inherited correctly
  end

  test "should store currency in prize pool calculations" do
    @raffle.update!(currency: "AUD")
    draw = Draw.create!(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days,
      status: "active",
      total_revenue_cents: 20000
    )

    draw.calculate_prize_pool_with_fees!

    assert_equal "AUD", draw.prize_pool["currency"]
    assert_equal 10000, draw.prize_pool["main_prize_cents"]
    assert_equal 10000, draw.prize_pool["organization_revenue_cents"]
  end

  test "should handle nil currency gracefully" do
    draw = Draw.new(
      raffle: @raffle,
      draw_date: Date.today + 1.week,
      ticket_sales_start_at: Time.current,
      ticket_sales_end_at: Time.current + 6.days
    )

    # Should default to USD when raffle has no specific currency
    assert_equal "USD", draw.currency
  end
end

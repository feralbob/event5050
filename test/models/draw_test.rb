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
end
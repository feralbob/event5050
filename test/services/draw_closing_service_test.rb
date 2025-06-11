require "test_helper"

class DrawClosingServiceTest < ActiveSupport::TestCase
  setup do
    @draw = draws(:one)
    # Ensure draw has valid dates before updating
    @draw.update!(
      status: :active, 
      ticket_sales_start_at: 2.hours.ago,
      ticket_sales_end_at: 1.minute.ago,
      draw_date: Date.today
    )
    @service = DrawClosingService.new(@draw)
  end
  
  test "should close draw when sales period ends" do
    assert @draw.active?
    
    result = @service.call
    
    assert result.success?
    assert @draw.reload.closed?
  end
  
  test "should calculate final prize pool" do
    # Create some tickets to generate revenue
    3.times do
      ticket = @draw.tickets.build(
        ticket_purchaser: ticket_purchasers(:one),
        price_cents: 500,
        status: :active
      )
      ticket.generate_ticket_number!
      ticket.save!
    end
    @draw.update!(total_revenue_cents: 1500) # $15
    
    @service.call
    
    @draw.reload
    assert_equal 750, @draw.prize_pool["main_prize_cents"] # 50% = $7.50
    assert_equal 750, @draw.prize_pool["organization_revenue_cents"]
  end
  
  test "should not close already closed draw" do
    @draw.update!(status: :closed)
    
    result = @service.call
    
    assert_not result.success?
    assert_equal "Draw is already closed", result.error
  end
  
  test "should not close draw if sales period not ended" do
    @draw.update!(ticket_sales_end_at: 1.hour.from_now)
    
    result = @service.call
    
    assert_not result.success?
    assert_equal "Sales period has not ended", result.error
  end
end
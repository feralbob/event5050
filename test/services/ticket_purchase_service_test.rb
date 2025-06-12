require "test_helper"

class TicketPurchaseServiceTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @raffle = raffles(:one)
    @draw = draws(:one)
    @draw.update!(total_revenue_cents: 0)
    
    ActsAsTenant.current_tenant = @organization
    
    # Clean up any existing pricing tiers
    @raffle.pricing_tiers.destroy_all
    
    # Create pricing tiers
    @single_tier = PricingTier.create!(
      raffle: @raffle,
      name: "Single Ticket",
      code: "single",
      ticket_quantity: 1,
      total_price_cents: 500,
      display_order: 1
    )
    
    @bundle_tier = PricingTier.create!(
      raffle: @raffle,
      name: "3 Ticket Bundle",
      code: "bundle_3",
      ticket_quantity: 3,
      total_price_cents: 1000,
      display_order: 2
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should create tickets with single pricing tier" do
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @single_tier,
      purchaser_attributes: {
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        phone: "555-1234"
      }
    )
    
    assert_difference("Ticket.count", 1) do
      result = service.purchase!
      assert result.success?
      assert_equal 1, result.tickets.count
      assert_equal @single_tier, result.tickets.first.pricing_tier
      assert_equal 500, result.tickets.first.price_cents
    end
  end

  test "should create multiple tickets with bundle pricing tier" do
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
    
    assert_difference("Ticket.count", 3) do
      result = service.purchase!
      assert result.success?
      assert_equal 3, result.tickets.count
      
      result.tickets.each do |ticket|
        assert_equal @bundle_tier, ticket.pricing_tier
        assert_equal 333, ticket.price_cents # 1000/3 = 333.33, rounded down
      end
    end
  end

  test "should update draw revenue" do
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @bundle_tier,
      purchaser_attributes: {
        first_name: "Bob",
        last_name: "Johnson",
        email: "bob@example.com",
        phone: "555-9999"
      }
    )
    
    assert_equal 0, @draw.total_revenue_cents
    
    result = service.purchase!
    assert result.success?
    
    @draw.reload
    assert_equal 1000, @draw.total_revenue_cents
  end

  test "should find existing ticket purchaser by email" do
    existing_purchaser = TicketPurchaser.create!(
      first_name: "Existing",
      last_name: "User",
      email: "existing@example.com",
      phone: "555-0000"
    )
    
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @single_tier,
      purchaser_attributes: {
        first_name: "Updated",
        last_name: "Name",
        email: "existing@example.com",
        phone: "555-1111"
      }
    )
    
    assert_no_difference("TicketPurchaser.count") do
      result = service.purchase!
      assert result.success?
      assert_equal existing_purchaser, result.ticket_purchaser
    end
  end

  test "should create new ticket purchaser if not found" do
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @single_tier,
      purchaser_attributes: {
        first_name: "New",
        last_name: "User",
        email: "new@example.com",
        phone: "555-2222"
      }
    )
    
    assert_difference("TicketPurchaser.count", 1) do
      result = service.purchase!
      assert result.success?
      assert_equal "new@example.com", result.ticket_purchaser.email
    end
  end

  test "should generate unique ticket numbers" do
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @bundle_tier,
      purchaser_attributes: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        phone: "555-3333"
      }
    )
    
    result = service.purchase!
    assert result.success?
    
    ticket_numbers = result.tickets.map(&:ticket_number)
    assert_equal 3, ticket_numbers.uniq.count
    
    # Check format
    ticket_numbers.each do |number|
      assert_match(/\A[A-Z0-9]{3}-[A-Z0-9]{3}-[A-Z0-9]{3}\z/, number)
    end
  end

  test "should rollback transaction on failure" do
    # Create a pricing tier with invalid data that will cause failure
    invalid_tier = PricingTier.new(
      raffle: @raffle,
      name: "Invalid",
      code: "invalid",
      ticket_quantity: 0, # This will cause division by zero
      total_price_cents: 1000
    )
    invalid_tier.save(validate: false) # Force save invalid data
    
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: invalid_tier,
      purchaser_attributes: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        phone: "555-4444"
      }
    )
    
    assert_no_difference(["Ticket.count", "TicketPurchaser.count"]) do
      result = service.purchase!
      assert_not result.success?
      assert result.error.present?
    end
    
    # Revenue should not change
    @draw.reload
    assert_equal 0, @draw.total_revenue_cents
  end

  test "should validate purchaser attributes" do
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @single_tier,
      purchaser_attributes: {
        first_name: "",
        last_name: "",
        email: "invalid-email",
        phone: ""
      }
    )
    
    result = service.purchase!
    assert_not result.success?
    assert result.error.present?
  end

  test "should validate draw is open for sales" do
    @draw.update!(status: :closed)
    
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @single_tier,
      purchaser_attributes: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        phone: "555-5555"
      }
    )
    
    result = service.purchase!
    assert_not result.success?
    assert_equal "Sales have ended for this draw", result.error
  end

  test "should validate pricing tier belongs to raffle" do
    other_raffle = Raffle.create!(
      organization: @organization,
      license: licenses(:one),
      name: "Other Raffle"
    )
    
    other_tier = PricingTier.create!(
      raffle: other_raffle,
      name: "Other Tier",
      code: "other",
      ticket_quantity: 1,
      total_price_cents: 500
    )
    
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: other_tier,
      purchaser_attributes: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        phone: "555-6666"
      }
    )
    
    result = service.purchase!
    assert_not result.success?
    assert_equal "Invalid pricing tier for this raffle", result.error
  end

  test "should validate pricing tier is active" do
    @single_tier.update!(active: false)
    
    service = TicketPurchaseService.new(
      draw: @draw,
      pricing_tier: @single_tier,
      purchaser_attributes: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        phone: "555-7777"
      }
    )
    
    result = service.purchase!
    assert_not result.success?
    assert_equal "This pricing tier is no longer available", result.error
  end
end
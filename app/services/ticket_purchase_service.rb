class TicketPurchaseService
  attr_reader :draw, :pricing_tier, :purchaser_attributes

  Result = Struct.new(:success?, :tickets, :ticket_purchaser, :ticket_purchase, :error, keyword_init: true)

  def initialize(draw:, pricing_tier:, purchaser_attributes:)
    @draw = draw
    @pricing_tier = pricing_tier
    @purchaser_attributes = purchaser_attributes
  end

  def purchase!
    return error_result("Sales have ended for this draw") unless draw.ticket_sales_open?
    return error_result("Invalid pricing tier for this raffle") unless valid_pricing_tier?
    return error_result("This pricing tier is no longer available") unless pricing_tier.active?

    ActiveRecord::Base.transaction do
      ticket_purchaser = find_or_create_ticket_purchaser!
      ticket_purchase = create_ticket_purchase!(ticket_purchaser)
      tickets = create_tickets!(ticket_purchaser, ticket_purchase)
      update_draw_revenue!(ticket_purchase)

      Result.new(
        success?: true,
        tickets: tickets,
        ticket_purchaser: ticket_purchaser,
        ticket_purchase: ticket_purchase,
        error: nil
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    error_result(e.record.errors.full_messages.join(", "))
  rescue StandardError => e
    error_result(e.message)
  end

  private

  def valid_pricing_tier?
    pricing_tier.raffle_id == draw.raffle_id
  end

  def find_or_create_ticket_purchaser!
    if purchaser_attributes[:email].present?
      ticket_purchaser = TicketPurchaser.find_or_initialize_by(
        email: purchaser_attributes[:email]
      )

      # Update attributes if it's a new record
      if ticket_purchaser.new_record?
        ticket_purchaser.assign_attributes(purchaser_attributes)
      end

      ticket_purchaser.save!
      ticket_purchaser
    else
      TicketPurchaser.create!(purchaser_attributes)
    end
  end

  def create_ticket_purchase!(ticket_purchaser)
    TicketPurchase.create!(
      draw: draw,
      ticket_purchaser: ticket_purchaser,
      pricing_tier: pricing_tier,
      total_amount: pricing_tier.total_price,
      currency: pricing_tier.currency,
      purchase_date: Time.current
    )
  end

  def create_tickets!(ticket_purchaser, ticket_purchase)
    tickets = []

    pricing_tier.ticket_quantity.times do
      ticket = draw.tickets.build(
        ticket_purchaser: ticket_purchaser,
        pricing_tier: pricing_tier,
        ticket_purchase: ticket_purchase,
        status: :active
      )
      ticket.generate_ticket_number!
      ticket.save!
      tickets << ticket
    end

    tickets
  end

  def update_draw_revenue!(ticket_purchase)
    # Use the ticket purchase total amount for precise revenue tracking
    draw.increment_revenue!(ticket_purchase.total_amount)
  end

  def error_result(message)
    Result.new(
      success?: false,
      tickets: [],
      ticket_purchaser: nil,
      ticket_purchase: nil,
      error: message
    )
  end
end

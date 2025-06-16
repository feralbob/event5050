class Ticket < ApplicationRecord
  belongs_to :draw
  belongs_to :ticket_purchaser
  belongs_to :pricing_tier, optional: true
  belongs_to :ticket_purchase, optional: true

  validates :ticket_number, presence: true, uniqueness: true
  validate :no_multiple_wins_per_draw

  # Enums
  enum :status, { active: 0, won: 1, refunded: 2 }, default: :active

  # Default values
  attribute :purchase_metadata, :jsonb, default: {}

  def formatted_price
    if ticket_purchase.present?
      # Calculate proportional share of purchase
      (ticket_purchase.total_amount / ticket_purchase.ticket_count).format
    elsif pricing_tier.present?
      # Fallback: calculate from pricing tier
      pricing_tier.price_per_ticket.format
    else
      "$0.00"
    end
  end

  # Get the effective price for this ticket
  def effective_price
    if ticket_purchase.present?
      # Proportional share of purchase
      ticket_purchase.total_amount / ticket_purchase.ticket_count
    elsif pricing_tier.present?
      # Fallback: calculate from pricing tier
      pricing_tier.price_per_ticket
    else
      Money.new(0, "USD")
    end
  end

  # Get currency from related models through inheritance chain
  def currency
    ticket_purchase&.currency || pricing_tier&.currency || draw&.currency
  end


  def generate_ticket_number!
    # Generate a human-readable ticket number like ABC-123-XYZ
    # Keep generating until we find a unique one
    loop do
      chars = ("A".."Z").to_a + ("0".."9").to_a
      self.ticket_number = 3.times.map { chars.sample(3).join }.join("-")
      break unless Ticket.exists?(ticket_number: self.ticket_number)
    end
  end

  private

  def no_multiple_wins_per_draw
    return unless won? && draw && ticket_purchaser

    existing_winner = Ticket.where(
      draw: draw,
      ticket_purchaser: ticket_purchaser,
      status: :won
    ).where.not(id: id).exists?

    if existing_winner
      errors.add(:base, "Purchaser has already won a prize in this draw")
    end
  end
end

class Ticket < ApplicationRecord
  belongs_to :draw
  belongs_to :ticket_purchaser
  
  validates :ticket_number, presence: true, uniqueness: true
  validates :price_cents, presence: true
  validate :no_multiple_wins_per_draw
  
  # Enums
  enum :status, { active: 0, won: 1, refunded: 2 }, default: :active
  
  # Default values
  attribute :purchase_metadata, :jsonb, default: {}
  
  def generate_ticket_number!
    # Generate a human-readable ticket number like ABC-123-XYZ
    chars = ('A'..'Z').to_a + ('0'..'9').to_a
    self.ticket_number = 3.times.map { chars.sample(3).join }.join('-')
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

class CreateDefaultPricingTiersForExistingRaffles < ActiveRecord::Migration[8.0]
  def up
    # Create default pricing tiers for existing raffles
    Raffle.find_each do |raffle|
      # Skip if raffle already has pricing tiers
      next if raffle.pricing_tiers.exists?

      # Create default pricing tiers
      raffle.pricing_tiers.create!([
        {
          name: "Single Ticket",
          code: "single",
          ticket_quantity: 1,
          total_price_cents: 500,
          display_order: 1,
          active: true
        },
        {
          name: "3 Ticket Bundle",
          code: "bundle3",
          ticket_quantity: 3,
          total_price_cents: 1000,
          display_order: 2,
          active: true,
          description: "Save $5!"
        }
      ])
    end

    # Update existing tickets to reference the single tier
    Ticket.where(pricing_tier_id: nil).find_each do |ticket|
      # Find the single ticket pricing tier for this ticket's draw's raffle
      single_tier = ticket.draw.raffle.pricing_tiers.find_by(code: "single")

      if single_tier
        ticket.update_columns(pricing_tier_id: single_tier.id)
      end
    end
  end

  def down
    # Remove pricing tier references from tickets
    Ticket.update_all(pricing_tier_id: nil)

    # Delete all pricing tiers
    PricingTier.delete_all
  end
end

class AddPricingTierToTickets < ActiveRecord::Migration[8.0]
  def change
    add_reference :tickets, :pricing_tier, foreign_key: true
  end
end

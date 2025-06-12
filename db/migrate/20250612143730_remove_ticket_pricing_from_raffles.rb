class RemoveTicketPricingFromRaffles < ActiveRecord::Migration[8.0]
  def change
    remove_column :raffles, :ticket_pricing, :jsonb
  end
end

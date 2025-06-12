class RemovePriceFromTickets < ActiveRecord::Migration[8.0]
  def change
    remove_column :tickets, :price_cents, :integer
    remove_column :tickets, :currency, :string
  end
end

class RenameTicketPurchasersToCustomers < ActiveRecord::Migration[8.0]
  def change
    rename_table :ticket_purchasers, :customers
    rename_column :tickets, :ticket_purchaser_id, :customer_id
    rename_column :ticket_purchases, :ticket_purchaser_id, :customer_id
  end
end

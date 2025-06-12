class AddTicketPurchaseToTickets < ActiveRecord::Migration[8.0]
  def change
    add_reference :tickets, :ticket_purchase, null: true, foreign_key: true
  end
end

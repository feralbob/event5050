class AddCurrencyToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :currency, :string, null: false, default: 'USD'
  end
end

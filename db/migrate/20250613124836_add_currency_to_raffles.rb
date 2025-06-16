class AddCurrencyToRaffles < ActiveRecord::Migration[8.0]
  def change
    add_column :raffles, :currency, :string, null: false, default: 'USD'
  end
end

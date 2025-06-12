class AddCurrencyToDraws < ActiveRecord::Migration[8.0]
  def change
    add_column :draws, :currency, :string, null: false, default: 'USD'
  end
end

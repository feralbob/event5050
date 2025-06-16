class RemoveDefaultFromDrawCurrency < ActiveRecord::Migration[8.0]
  def change
    change_column_default :draws, :currency, from: 'USD', to: nil
  end
end

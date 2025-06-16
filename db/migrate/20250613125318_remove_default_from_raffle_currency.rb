class RemoveDefaultFromRaffleCurrency < ActiveRecord::Migration[8.0]
  def change
    change_column_default :raffles, :currency, from: 'USD', to: nil
  end
end

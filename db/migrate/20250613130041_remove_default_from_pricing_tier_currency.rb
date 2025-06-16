class RemoveDefaultFromPricingTierCurrency < ActiveRecord::Migration[8.0]
  def change
    change_column_default :pricing_tiers, :currency, from: 'USD', to: nil
  end
end

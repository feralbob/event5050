class AddCurrencyToPricingTiers < ActiveRecord::Migration[8.0]
  def change
    add_column :pricing_tiers, :currency, :string, null: false, default: 'USD'
  end
end

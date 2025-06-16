class AddCurrencyToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :currency, :string, null: false, default: 'USD'
  end
end

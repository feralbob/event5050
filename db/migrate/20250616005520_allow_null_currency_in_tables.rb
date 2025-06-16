class AllowNullCurrencyInTables < ActiveRecord::Migration[8.0]
  def change
    # Allow NULL for currency columns to simplify inheritance
    # NULL means "inherit from parent or use system default"
    change_column_null :draws, :currency, true
    change_column_null :pricing_tiers, :currency, true
    change_column_null :raffles, :currency, true
    
    # Organizations should still require currency as they are the root
    # change_column_null :organizations, :currency, false # Already NOT NULL
  end
end

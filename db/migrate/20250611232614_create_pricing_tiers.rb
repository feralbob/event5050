class CreatePricingTiers < ActiveRecord::Migration[8.0]
  def change
    create_table :pricing_tiers do |t|
      t.references :raffle, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.integer :ticket_quantity, null: false
      t.integer :total_price_cents, null: false
      t.integer :display_order, default: 0
      t.boolean :active, default: true
      t.string :description
      t.jsonb :metadata, default: {}
      
      t.timestamps
      
      t.index [:raffle_id, :code], unique: true
      t.index [:raffle_id, :active]
    end
  end
end

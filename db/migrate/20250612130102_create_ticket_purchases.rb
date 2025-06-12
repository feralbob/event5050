class CreateTicketPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_purchases do |t|
      t.references :draw, null: false, foreign_key: true
      t.references :ticket_purchaser, null: false, foreign_key: true
      t.references :pricing_tier, null: false, foreign_key: true
      t.integer :total_amount_cents, null: false
      t.string :currency, null: false, default: 'USD'
      t.datetime :purchase_date, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :ticket_purchases, :purchase_date
    add_index :ticket_purchases, [ :draw_id, :purchase_date ]
  end
end

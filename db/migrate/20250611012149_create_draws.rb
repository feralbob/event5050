class CreateDraws < ActiveRecord::Migration[8.0]
  def change
    create_table :draws do |t|
      t.references :raffle, null: false, foreign_key: true
      t.date :draw_date
      t.datetime :ticket_sales_start_at
      t.datetime :ticket_sales_end_at
      t.string :status
      t.integer :total_revenue_cents
      t.jsonb :prize_pool

      t.timestamps
    end
  end
end

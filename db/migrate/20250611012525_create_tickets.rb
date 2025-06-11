class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.references :draw, null: false, foreign_key: true
      t.references :ticket_purchaser, null: false, foreign_key: true
      t.string :ticket_number
      t.integer :price_cents
      t.string :status
      t.string :prize_won
      t.jsonb :purchase_metadata

      t.timestamps
    end
    add_index :tickets, :ticket_number, unique: true
  end
end

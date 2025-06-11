class CreateRaffles < ActiveRecord::Migration[8.0]
  def change
    create_table :raffles do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :license, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :status
      t.boolean :recurring
      t.string :recurrence_rule
      t.jsonb :ticket_pricing

      t.timestamps
    end
  end
end

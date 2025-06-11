class CreateTicketPurchasers < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_purchasers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone

      t.timestamps
    end
    add_index :ticket_purchasers, :email
  end
end

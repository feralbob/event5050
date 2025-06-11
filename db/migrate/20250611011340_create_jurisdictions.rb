class CreateJurisdictions < ActiveRecord::Migration[8.0]
  def change
    create_table :jurisdictions do |t|
      t.string :name
      t.geometry :boundary

      t.timestamps
    end
    add_index :jurisdictions, :name, unique: true
    add_index :jurisdictions, :boundary, using: :gist
  end
end

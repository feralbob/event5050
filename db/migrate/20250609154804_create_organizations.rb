class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :organizations, :name, unique: true
  end
end

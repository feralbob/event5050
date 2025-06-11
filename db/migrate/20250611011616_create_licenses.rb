class CreateLicenses < ActiveRecord::Migration[8.0]
  def change
    create_table :licenses do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :jurisdiction, null: false, foreign_key: true
      t.string :license_number
      t.date :issued_at
      t.date :expires_at
      t.string :license_type
      t.date :event_date
      t.string :recurrence_rule
      t.jsonb :requirements

      t.timestamps
    end
    add_index :licenses, :license_number, unique: true
  end
end

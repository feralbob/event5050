class RemovePasswordFieldsFromCustomers < ActiveRecord::Migration[8.0]
  def change
    remove_column :customers, :password_digest, :string
    remove_column :customers, :reset_password_token, :string
    remove_column :customers, :reset_password_sent_at, :datetime
  end
end

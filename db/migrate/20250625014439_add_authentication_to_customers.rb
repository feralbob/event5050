class AddAuthenticationToCustomers < ActiveRecord::Migration[8.0]
  def change
    # WebAuthn fields
    add_column :customers, :webauthn_id, :string
    add_index :customers, :webauthn_id, unique: true

    # Email confirmation fields
    add_column :customers, :email_confirmed_at, :datetime
    add_column :customers, :confirmation_token, :string
    add_column :customers, :confirmation_sent_at, :datetime
    add_index :customers, :confirmation_token, unique: true

    # Optional password for backup authentication
    add_column :customers, :password_digest, :string

    # Session and tracking fields
    add_column :customers, :session_token, :string
    add_column :customers, :last_sign_in_at, :datetime
    add_column :customers, :last_sign_in_ip, :string
    add_column :customers, :sign_in_count, :integer, default: 0, null: false

    # Password reset fields (for backup authentication)
    add_column :customers, :reset_password_token, :string
    add_column :customers, :reset_password_sent_at, :datetime
    add_index :customers, :reset_password_token, unique: true

    # Make email unique and not null
    change_column_null :customers, :email, false
    add_index :customers, :email, unique: true, name: 'unique_customers_email'
    remove_index :customers, name: 'index_customers_on_email' if index_exists?(:customers, :email, name: 'index_customers_on_email')
  end
end

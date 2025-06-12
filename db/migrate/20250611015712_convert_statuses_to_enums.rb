class ConvertStatusesToEnums < ActiveRecord::Migration[8.0]
  def up
    # Convert Raffle status (draft: 0, active: 1)
    add_column :raffles, :status_new, :integer, default: 0, null: false

    # Migrate existing data
    execute <<-SQL
      UPDATE raffles#{' '}
      SET status_new = CASE#{' '}
        WHEN status = 'draft' THEN 0
        WHEN status = 'active' THEN 1
        ELSE 0
      END
    SQL

    remove_column :raffles, :status
    rename_column :raffles, :status_new, :status

    # Convert Draw status (scheduled: 0, active: 1, closed: 2, drawn: 3)
    add_column :draws, :status_new, :integer, default: 0, null: false

    execute <<-SQL
      UPDATE draws#{' '}
      SET status_new = CASE#{' '}
        WHEN status = 'scheduled' THEN 0
        WHEN status = 'active' THEN 1
        WHEN status = 'closed' THEN 2
        WHEN status = 'drawn' THEN 3
        ELSE 0
      END
    SQL

    remove_column :draws, :status
    rename_column :draws, :status_new, :status

    # Convert Ticket status (active: 0, won: 1)
    add_column :tickets, :status_new, :integer, default: 0, null: false

    execute <<-SQL
      UPDATE tickets#{' '}
      SET status_new = CASE#{' '}
        WHEN status = 'active' THEN 0
        WHEN status = 'won' THEN 1
        ELSE 0
      END
    SQL

    remove_column :tickets, :status
    rename_column :tickets, :status_new, :status

    # Convert License license_type (single: 0, recurring: 1)
    add_column :licenses, :license_type_new, :integer, null: true

    execute <<-SQL
      UPDATE licenses#{' '}
      SET license_type_new = CASE#{' '}
        WHEN license_type = 'single' THEN 0
        WHEN license_type = 'recurring' THEN 1
        ELSE NULL
      END
    SQL

    remove_column :licenses, :license_type
    rename_column :licenses, :license_type_new, :license_type
  end

  def down
    # Reverse the migration
    # Convert Raffle status back to string
    add_column :raffles, :status_new, :string, default: 'draft'

    execute <<-SQL
      UPDATE raffles#{' '}
      SET status_new = CASE#{' '}
        WHEN status = 0 THEN 'draft'
        WHEN status = 1 THEN 'active'
        ELSE 'draft'
      END
    SQL

    remove_column :raffles, :status
    rename_column :raffles, :status_new, :status

    # Convert Draw status back to string
    add_column :draws, :status_new, :string, default: 'scheduled'

    execute <<-SQL
      UPDATE draws#{' '}
      SET status_new = CASE#{' '}
        WHEN status = 0 THEN 'scheduled'
        WHEN status = 1 THEN 'active'
        WHEN status = 2 THEN 'closed'
        WHEN status = 3 THEN 'drawn'
        ELSE 'scheduled'
      END
    SQL

    remove_column :draws, :status
    rename_column :draws, :status_new, :status

    # Convert Ticket status back to string
    add_column :tickets, :status_new, :string, default: 'active'

    execute <<-SQL
      UPDATE tickets#{' '}
      SET status_new = CASE#{' '}
        WHEN status = 0 THEN 'active'
        WHEN status = 1 THEN 'won'
        ELSE 'active'
      END
    SQL

    remove_column :tickets, :status
    rename_column :tickets, :status_new, :status

    # Convert License license_type back to string
    add_column :licenses, :license_type_new, :string

    execute <<-SQL
      UPDATE licenses#{' '}
      SET license_type_new = CASE#{' '}
        WHEN license_type = 0 THEN 'single'
        WHEN license_type = 1 THEN 'recurring'
        ELSE NULL
      END
    SQL

    remove_column :licenses, :license_type
    rename_column :licenses, :license_type_new, :license_type
  end
end

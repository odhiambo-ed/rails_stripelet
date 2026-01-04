class CreateLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_entries do |t|
      # Polymorphic association - can be attached to any entity (Customer, Invoice, etc.)
      t.references :entity, polymorphic: true, null: false, index: true

      # Entry type (credit, debit, refund, etc.)
      t.string :entry_type, null: false

      # Amount in cents (can be negative for debits)
      t.bigint :amount_cents, null: false

      # Currency code
      t.string :currency, null: false

      # Idempotency key for preventing duplicate entries
      t.string :idempotency_key, null: false

      # Flexible storage for additional data
      t.jsonb :metadata, default: {}, null: false

      # Only created_at - NO updated_at because ledger entries are immutable
      t.datetime :created_at, null: false
    end

    # =====================
    # Indexes
    # =====================
    add_index :ledger_entries, :idempotency_key, unique: true
    add_index :ledger_entries, :entry_type
    add_index :ledger_entries, :currency
    add_index :ledger_entries, :created_at

    # Composite index for efficiently querying entity balances
    add_index :ledger_entries, [ :entity_type, :entity_id, :currency ],
              name: "idx_ledger_entries_entity_currency"

    # Composite index for entity with created_at for time-series queries
    add_index :ledger_entries, [ :entity_type, :entity_id, :created_at ],
              name: "idx_ledger_entries_entity_time"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :ledger_entries,
      "entry_type IN ('credit', 'debit', 'refund', 'adjustment', 'fee')",
      name: "chk_ledger_entry_type_valid"

    add_check_constraint :ledger_entries,
      "currency IN ('usd', 'eur', 'gbp', 'jpy')",
      name: "chk_ledger_currency_valid"

    add_check_constraint :ledger_entries,
      "idempotency_key != ''",
      name: "chk_ledger_idempotency_key_not_empty"

    # =====================
    # Comments
    # =====================
    change_table_comment :ledger_entries,
      "Immutable financial ledger entries - NEVER UPDATE OR DELETE"

    change_column_comment :ledger_entries, :entity_type,
      "Type of entity this entry belongs to (Customer, Invoice, etc.)"

    change_column_comment :ledger_entries, :entity_id,
      "ID of the entity this entry belongs to"

    change_column_comment :ledger_entries, :entry_type,
      "Type of entry (credit, debit, refund, adjustment, fee)"

    change_column_comment :ledger_entries, :amount_cents,
      "Amount in cents (positive for credits, negative for debits)"

    change_column_comment :ledger_entries, :currency,
      "ISO 4217 currency code"

    change_column_comment :ledger_entries, :idempotency_key,
      "Unique key to prevent duplicate entries"

    change_column_comment :ledger_entries, :metadata,
      "Additional data about the ledger entry"
  end
end

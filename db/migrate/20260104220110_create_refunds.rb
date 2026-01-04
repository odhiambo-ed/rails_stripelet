class CreateRefunds < ActiveRecord::Migration[8.0]
  def change
    create_table :refunds do |t|
      # Unique refund identifier
      t.string :refund_id, null: false

      # Invoice being refunded
      t.references :invoice, null: false, foreign_key: true

      # Refund amount in cents
      t.bigint :amount_cents, null: false

      # Currency of the refund
      t.string :currency, null: false

      # Refund status (pending, succeeded, failed, canceled)
      t.string :status, null: false, default: 'pending'

      # Reason for the refund
      t.string :reason

      # Additional refund data
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :refunds, :refund_id, unique: true
    add_index :refunds, :status
    add_index :refunds, :created_at
    add_index :refunds, [ :invoice_id, :status ]

    # =====================
    # Constraints
    # =====================
    add_check_constraint :refunds,
      "status IN ('pending', 'succeeded', 'failed', 'canceled')",
      name: "chk_refund_status_valid"

    add_check_constraint :refunds,
      "amount_cents > 0",
      name: "chk_refund_amount_positive"

    add_check_constraint :refunds,
      "currency IN ('usd', 'eur', 'gbp', 'jpy')",
      name: "chk_refund_currency_valid"

    # =====================
    # Comments
    # =====================
    change_table_comment :refunds,
      "Refunds issued against invoices"

    change_column_comment :refunds, :refund_id,
      "External-facing refund identifier (re_xxx)"

    change_column_comment :refunds, :amount_cents,
      "Refund amount in cents (must not exceed invoice total)"

    change_column_comment :refunds, :status,
      "Refund status (pending, succeeded, failed, canceled)"

    change_column_comment :refunds, :reason,
      "Reason for the refund (e.g., 'requested_by_customer', 'duplicate')"
  end
end

class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_id, null: false
      t.references :customer, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true
      t.string :status, null: false, default: 'draft'
      t.string :currency, null: false
      t.bigint :subtotal_cents, null: false, default: 0
      t.bigint :tax_cents, null: false, default: 0
      t.bigint :total_cents, null: false, default: 0
      t.bigint :amount_paid_cents, null: false, default: 0
      t.bigint :amount_refunded_cents, null: false, default: 0
      t.bigint :amount_due_cents, null: false, default: 0
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.date :due_date
      t.datetime :finalized_at
      t.datetime :paid_at
      t.datetime :voided_at
      t.jsonb :metadata, default: {}, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :invoices, :invoice_id, unique: true
    add_index :invoices, :status
    add_index :invoices, :created_at
    add_index :invoices, [ :customer_id, :status ]
    add_index :invoices, [ :customer_id, :created_at ]

    # Partial indexes for common queries
    add_index :invoices,
              :due_date,
              where: "status = 'open' AND deleted_at IS NULL",
              name: "idx_invoices_due_date_open"

    add_index :invoices,
              :paid_at,
              where: "status = 'paid' AND deleted_at IS NULL",
              name: "idx_invoices_paid_at"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :invoices,
      "status IN ('draft', 'open', 'paid', 'void', 'uncollectible', 'partially_refunded', 'refunded')",
      name: "chk_invoice_status_valid"

    add_check_constraint :invoices,
      "currency IN ('usd', 'eur', 'gbp', 'jpy')",
      name: "chk_invoice_currency_valid"

    add_check_constraint :invoices,
      <<~SQL.squish,
        subtotal_cents >= 0 AND
        tax_cents >= 0 AND
        total_cents >= 0 AND
        amount_paid_cents >= 0 AND
        amount_refunded_cents >= 0 AND
        amount_due_cents >= 0
      SQL
      name: "chk_invoice_amounts_positive"

    add_check_constraint :invoices,
      "total_cents = subtotal_cents + tax_cents",
      name: "chk_invoice_total_calculation"

    add_check_constraint :invoices,
      "amount_due_cents = total_cents - amount_paid_cents + amount_refunded_cents",
      name: "chk_invoice_amount_due_calculation"

    add_check_constraint :invoices,
      "period_end > period_start",
      name: "chk_invoice_period_order"

    add_check_constraint :invoices,
      "amount_paid_cents <= total_cents",
      name: "chk_invoice_paid_not_exceed_total"

    add_check_constraint :invoices,
      "amount_refunded_cents <= total_cents",
      name: "chk_invoice_refunded_not_exceed_total"

    # =====================
    # Comments
    # =====================
    change_table_comment :invoices,
      "Customer invoices with immutability once finalized"

    change_column_comment :invoices, :invoice_id,
      "External-facing invoice identifier (inv_xxx)"

    change_column_comment :invoices, :status,
      "Invoice status (draft, open, paid, void, uncollectible, partially_refunded, refunded)"

    change_column_comment :invoices, :subtotal_cents,
      "Sum of line items before tax"

    change_column_comment :invoices, :tax_cents,
      "Tax amount in cents"

    change_column_comment :invoices, :total_cents,
      "Total amount due (subtotal + tax)"

    change_column_comment :invoices, :amount_paid_cents,
      "Amount paid by customer"

    change_column_comment :invoices, :amount_refunded_cents,
      "Amount refunded to customer"

    change_column_comment :invoices, :amount_due_cents,
      "Calculated: total - paid + refunded"

    change_column_comment :invoices, :period_start,
      "Start date of billing period"

    change_column_comment :invoices, :period_end,
      "End date of billing period"

    change_column_comment :invoices, :due_date,
      "Payment due date"

    change_column_comment :invoices, :finalized_at,
      "When invoice moved from draft to open (immutable after this)"

    change_column_comment :invoices, :paid_at,
      "When invoice was fully paid"

    change_column_comment :invoices, :voided_at,
      "When invoice was voided/canceled"

    change_column_comment :invoices, :metadata,
      "Flexible JSONB storage for custom invoice attributes"
  end
end

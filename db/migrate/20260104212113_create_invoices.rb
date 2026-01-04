class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_id
      t.references :customer, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true
      t.string :status
      t.string :currency
      t.bigint :subtotal_cents
      t.bigint :tax_cents
      t.bigint :total_cents
      t.bigint :amount_paid_cents
      t.bigint :amount_refunded_cents
      t.bigint :amount_due_cents
      t.date :period_start
      t.date :period_end
      t.date :due_date
      t.datetime :finalized_at
      t.datetime :paid_at
      t.datetime :voided_at
      t.jsonb :metadata

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :invoices, :invoice_id, unique: true
    add_index :invoices, :customer_id
    add_index :invoices, :subscription_id
    add_index :invoices, :status
    add_index :invoices, :created_at

    add_index :invoices,
              :due_date,
              where: "status = 'open'",
              name: "idx_invoices_due_date_open"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :invoices,
      "status IN ('draft', 'open', 'paid', 'void', 'uncollectible', 'partially_refunded', 'refunded')",
      name: "chk_invoice_status"

    add_check_constraint :invoices,
      <<~SQL.squish,
        subtotal_cents >= 0 AND
        tax_cents >= 0 AND
        total_cents >= 0 AND
        amount_paid_cents >= 0 AND
        amount_refunded_cents >= 0
      SQL
      name: "chk_invoice_amounts_positive"

    add_check_constraint :invoices,
      "total_cents = subtotal_cents + tax_cents",
      name: "chk_invoice_total_calculation"

    add_check_constraint :invoices,
      "amount_due_cents = total_cents - amount_paid_cents + amount_refunded_cents",
      name: "chk_invoice_amount_due"

    # =====================
    # Comments
    # =====================
    change_table_comment :invoices,
      "Customer invoices (immutable once finalized)"

    change_column_comment :invoices, :finalized_at,
      "When invoice moved from draft to open"

    change_column_comment :invoices, :amount_due_cents,
      "Calculated: total - paid + refunded"
  end
end

class CreateInvoiceLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.text :description
      t.decimal :quantity
      t.bigint :unit_amount_cents
      t.bigint :amount_cents
      t.string :currency
      t.date :period_start
      t.date :period_end
      t.jsonb :metadata

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :invoice_line_items, :invoice_id

    # =====================
    # Constraints
    # =====================
    add_check_constraint :invoice_line_items,
      "quantity > 0",
      name: "chk_invoice_line_items_quantity_positive"

    add_check_constraint :invoice_line_items,
      "amount_cents = (unit_amount_cents * quantity)::BIGINT",
      name: "chk_invoice_line_items_amount_calculation"

    # =====================
    # Comments
    # =====================
    change_table_comment :invoice_line_items,
      "Line items for invoices (subscription charges, usage, etc.)"

    change_column_comment :invoice_line_items, :quantity,
      "Quantity of units (e.g., API calls, storage GB)"
  end
end

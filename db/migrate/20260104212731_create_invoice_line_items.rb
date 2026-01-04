class CreateInvoiceLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: { on_delete: :cascade }
      t.text :description, null: false
      t.decimal :quantity, null: false, precision: 10, scale: 2
      t.bigint :unit_amount_cents, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.date :period_start
      t.date :period_end
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :invoice_line_items, :currency

    # =====================
    # Constraints
    # =====================
    add_check_constraint :invoice_line_items,
      "quantity > 0",
      name: "chk_invoice_line_items_quantity_positive"

    add_check_constraint :invoice_line_items,
      "unit_amount_cents >= 0",
      name: "chk_invoice_line_items_unit_amount_positive"

    add_check_constraint :invoice_line_items,
      "amount_cents >= 0",
      name: "chk_invoice_line_items_amount_positive"

    add_check_constraint :invoice_line_items,
      "amount_cents = (unit_amount_cents::numeric * quantity)::BIGINT",
      name: "chk_invoice_line_items_amount_calculation"

    add_check_constraint :invoice_line_items,
      "currency IN ('usd', 'eur', 'gbp', 'jpy')",
      name: "chk_invoice_line_items_currency_valid"

    add_check_constraint :invoice_line_items,
      "period_end IS NULL OR period_start IS NULL OR period_end >= period_start",
      name: "chk_invoice_line_items_period_order"

    # =====================
    # Comments
    # =====================
    change_table_comment :invoice_line_items,
      "Line items for invoices (subscription charges, usage, one-time fees, etc.) - cascade deleted with invoice"

    change_column_comment :invoice_line_items, :description,
      "Item description (e.g., 'Pro Plan Monthly', 'API Usage')"

    change_column_comment :invoice_line_items, :quantity,
      "Quantity of units (e.g., 1 for subscription, number of API calls, GB of storage)"

    change_column_comment :invoice_line_items, :unit_amount_cents,
      "Price per unit in cents"

    change_column_comment :invoice_line_items, :amount_cents,
      "Total line item amount (quantity * unit_amount_cents)"

    change_column_comment :invoice_line_items, :currency,
      "ISO 4217 currency code"

    change_column_comment :invoice_line_items, :period_start,
      "Start date of billing period for this line item (if applicable)"

    change_column_comment :invoice_line_items, :period_end,
      "End date of billing period for this line item (if applicable)"

    change_column_comment :invoice_line_items, :metadata,
      "Flexible JSONB storage for custom line item attributes"
  end
end

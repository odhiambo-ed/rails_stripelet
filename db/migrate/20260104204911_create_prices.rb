class CreatePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :prices do |t|
      t.string :price_id, null: false
      t.references :product, null: false, foreign_key: true
      t.string :currency, null: false
      t.bigint :amount_cents, null: false
      t.string :billing_scheme, null: false, default: 'per_unit'
      t.string :interval, null: false
      t.integer :interval_count, null: false, default: 1
      t.boolean :active, default: true, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :prices, :price_id, unique: true
    add_index :prices, :currency
    add_index :prices, :active
    add_index :prices, [ :product_id, :currency ]
    add_index :prices, [ :product_id, :active ]

    # =====================
    # Constraints
    # =====================
    add_check_constraint :prices,
      "amount_cents > 0",
      name: "chk_amount_cents_positive"

    add_check_constraint :prices,
      "interval_count > 0",
      name: "chk_interval_count_positive"

    add_check_constraint :prices,
      "billing_scheme IN ('per_unit', 'tiered')",
      name: "chk_billing_scheme_valid"

    add_check_constraint :prices,
      "interval IN ('day', 'week', 'month', 'year')",
      name: "chk_interval_valid"

    add_check_constraint :prices,
      "currency IN ('usd', 'eur', 'gbp', 'jpy')",
      name: "chk_currency_valid"

    # =====================
    # Comments
    # =====================
    change_table_comment :prices,
      "Pricing configurations for products with currency and billing support"

    change_column_comment :prices, :price_id,
      "External-facing price identifier (price_xxx)"

    change_column_comment :prices, :amount_cents,
      "Price in smallest currency unit (cents for USD/EUR/GBP, yen for JPY)"

    change_column_comment :prices, :currency,
      "ISO 4217 currency code (usd, eur, gbp, jpy)"

    change_column_comment :prices, :interval,
      "Billing frequency (day, week, month, year)"

    change_column_comment :prices, :interval_count,
      "Number of intervals (e.g., 3 for quarterly billing)"

    change_column_comment :prices, :billing_scheme,
      "Pricing model: per_unit (flat rate) or tiered (volume-based)"

    change_column_comment :prices, :metadata,
      "Flexible JSONB storage for custom pricing attributes"
  end
end

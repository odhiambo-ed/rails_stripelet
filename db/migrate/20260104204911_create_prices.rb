class CreatePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :prices do |t|
      t.string :price_id
      t.references :product, null: false, foreign_key: true
      t.string :currency
      t.bigint :amount_cents
      t.string :billing_scheme
      t.string :interval
      t.integer :interval_count
      t.boolean :active
      t.jsonb :metadata

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :prices, :price_id, unique: true
    add_index :prices, :product_id
    add_index :prices, :currency
    add_index :prices, :active

    # =====================
    # Constraints
    # =====================
    add_check_constraint :prices,
      "amount_cents >= 0",
      name: "chk_amount_positive"

    add_check_constraint :prices,
      "interval_count > 0",
      name: "chk_interval_count_positive"

    add_check_constraint :prices,
      "billing_scheme IN ('per_unit', 'tiered')",
      name: "chk_billing_scheme"

    # =====================
    # Comments
    # =====================
    change_table_comment :prices,
      "Pricing configurations for products"

    change_column_comment :prices, :amount_cents,
      "Price in smallest currency unit (cents)"

    change_column_comment :prices, :interval,
      "Billing frequency (month, year, etc.)"

    change_column_comment :prices, :interval_count,
      "Number of intervals (e.g., 3 for quarterly)"
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_04_204911) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", comment: "Customer accounts that can have subscriptions and be billed", force: :cascade do |t|
    t.string "customer_id", comment: "External-facing customer identifier (cus_xxx)"
    t.string "email"
    t.string "name"
    t.string "currency"
    t.jsonb "metadata", comment: "Flexible JSONB storage for custom attributes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_customers_on_created_at"
    t.index ["customer_id"], name: "index_customers_on_customer_id", unique: true
    t.index ["email"], name: "idx_customers_email", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "prices", comment: "Pricing configurations for products with currency and billing support", force: :cascade do |t|
    t.string "price_id", null: false, comment: "External-facing price identifier (price_xxx)"
    t.bigint "product_id", null: false
    t.string "currency", null: false, comment: "ISO 4217 currency code (usd, eur, gbp, jpy)"
    t.bigint "amount_cents", null: false, comment: "Price in smallest currency unit (cents for USD/EUR/GBP, yen for JPY)"
    t.string "billing_scheme", default: "per_unit", null: false, comment: "Pricing model: per_unit (flat rate) or tiered (volume-based)"
    t.string "interval", null: false, comment: "Billing frequency (day, week, month, year)"
    t.integer "interval_count", default: 1, null: false, comment: "Number of intervals (e.g., 3 for quarterly billing)"
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false, comment: "Flexible JSONB storage for custom pricing attributes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_prices_on_active"
    t.index ["currency"], name: "index_prices_on_currency"
    t.index ["price_id"], name: "index_prices_on_price_id", unique: true
    t.index ["product_id", "active"], name: "index_prices_on_product_id_and_active"
    t.index ["product_id", "currency"], name: "index_prices_on_product_id_and_currency"
    t.index ["product_id"], name: "index_prices_on_product_id"
    t.check_constraint "\"interval\"::text = ANY (ARRAY['day'::character varying, 'week'::character varying, 'month'::character varying, 'year'::character varying]::text[])", name: "chk_interval_valid"
    t.check_constraint "amount_cents > 0", name: "chk_amount_cents_positive"
    t.check_constraint "billing_scheme::text = ANY (ARRAY['per_unit'::character varying, 'tiered'::character varying]::text[])", name: "chk_billing_scheme_valid"
    t.check_constraint "currency::text = ANY (ARRAY['usd'::character varying, 'eur'::character varying, 'gbp'::character varying, 'jpy'::character varying]::text[])", name: "chk_currency_valid"
    t.check_constraint "interval_count > 0", name: "chk_interval_count_positive"
  end

  create_table "products", comment: "Billable products/services that customers can subscribe to", force: :cascade do |t|
    t.string "product_id", null: false, comment: "External-facing product identifier (prod_xxx)"
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false, comment: "Flexible JSONB storage for custom attributes (features, tiers, etc.)"
    t.datetime "deleted_at", comment: "Soft delete timestamp for archiving products"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "created_at"], name: "index_products_on_active_and_created_at"
    t.index ["active"], name: "index_products_on_active"
    t.index ["created_at"], name: "index_products_on_created_at"
    t.index ["name"], name: "index_products_on_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["product_id"], name: "index_products_on_product_id", unique: true
    t.check_constraint "name::text <> ''::text", name: "products_name_not_empty"
  end

  add_foreign_key "prices", "products"
end

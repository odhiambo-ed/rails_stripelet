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

ActiveRecord::Schema[8.0].define(version: 2026_01_04_212731) do
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

  create_table "invoice_line_items", comment: "Line items for invoices (subscription charges, usage, one-time fees, etc.) - cascade deleted with invoice", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.text "description", null: false, comment: "Item description (e.g., 'Pro Plan Monthly', 'API Usage')"
    t.decimal "quantity", precision: 10, scale: 2, null: false, comment: "Quantity of units (e.g., 1 for subscription, number of API calls, GB of storage)"
    t.bigint "unit_amount_cents", null: false, comment: "Price per unit in cents"
    t.bigint "amount_cents", null: false, comment: "Total line item amount (quantity * unit_amount_cents)"
    t.string "currency", null: false, comment: "ISO 4217 currency code"
    t.date "period_start", comment: "Start date of billing period for this line item (if applicable)"
    t.date "period_end", comment: "End date of billing period for this line item (if applicable)"
    t.jsonb "metadata", default: {}, null: false, comment: "Flexible JSONB storage for custom line item attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency"], name: "index_invoice_line_items_on_currency"
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
    t.check_constraint "amount_cents = (unit_amount_cents::numeric * quantity)::bigint", name: "chk_invoice_line_items_amount_calculation"
    t.check_constraint "amount_cents >= 0", name: "chk_invoice_line_items_amount_positive"
    t.check_constraint "currency::text = ANY (ARRAY['usd'::character varying, 'eur'::character varying, 'gbp'::character varying, 'jpy'::character varying]::text[])", name: "chk_invoice_line_items_currency_valid"
    t.check_constraint "period_end IS NULL OR period_start IS NULL OR period_end >= period_start", name: "chk_invoice_line_items_period_order"
    t.check_constraint "quantity > 0::numeric", name: "chk_invoice_line_items_quantity_positive"
    t.check_constraint "unit_amount_cents >= 0", name: "chk_invoice_line_items_unit_amount_positive"
  end

  create_table "invoices", comment: "Customer invoices with immutability once finalized", force: :cascade do |t|
    t.string "invoice_id", null: false, comment: "External-facing invoice identifier (inv_xxx)"
    t.bigint "customer_id", null: false
    t.bigint "subscription_id", null: false
    t.string "status", default: "draft", null: false, comment: "Invoice status (draft, open, paid, void, uncollectible, partially_refunded, refunded)"
    t.string "currency", null: false
    t.bigint "subtotal_cents", default: 0, null: false, comment: "Sum of line items before tax"
    t.bigint "tax_cents", default: 0, null: false, comment: "Tax amount in cents"
    t.bigint "total_cents", default: 0, null: false, comment: "Total amount due (subtotal + tax)"
    t.bigint "amount_paid_cents", default: 0, null: false, comment: "Amount paid by customer"
    t.bigint "amount_refunded_cents", default: 0, null: false, comment: "Amount refunded to customer"
    t.bigint "amount_due_cents", default: 0, null: false, comment: "Calculated: total - paid + refunded"
    t.date "period_start", null: false, comment: "Start date of billing period"
    t.date "period_end", null: false, comment: "End date of billing period"
    t.date "due_date", comment: "Payment due date"
    t.datetime "finalized_at", comment: "When invoice moved from draft to open (immutable after this)"
    t.datetime "paid_at", comment: "When invoice was fully paid"
    t.datetime "voided_at", comment: "When invoice was voided/canceled"
    t.jsonb "metadata", default: {}, null: false, comment: "Flexible JSONB storage for custom invoice attributes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_invoices_on_created_at"
    t.index ["customer_id", "created_at"], name: "index_invoices_on_customer_id_and_created_at"
    t.index ["customer_id", "status"], name: "index_invoices_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["due_date"], name: "idx_invoices_due_date_open", where: "(((status)::text = 'open'::text) AND (deleted_at IS NULL))"
    t.index ["invoice_id"], name: "index_invoices_on_invoice_id", unique: true
    t.index ["paid_at"], name: "idx_invoices_paid_at", where: "(((status)::text = 'paid'::text) AND (deleted_at IS NULL))"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["subscription_id"], name: "index_invoices_on_subscription_id"
    t.check_constraint "amount_due_cents = (total_cents - amount_paid_cents + amount_refunded_cents)", name: "chk_invoice_amount_due_calculation"
    t.check_constraint "amount_paid_cents <= total_cents", name: "chk_invoice_paid_not_exceed_total"
    t.check_constraint "amount_refunded_cents <= total_cents", name: "chk_invoice_refunded_not_exceed_total"
    t.check_constraint "currency::text = ANY (ARRAY['usd'::character varying, 'eur'::character varying, 'gbp'::character varying, 'jpy'::character varying]::text[])", name: "chk_invoice_currency_valid"
    t.check_constraint "period_end > period_start", name: "chk_invoice_period_order"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'open'::character varying, 'paid'::character varying, 'void'::character varying, 'uncollectible'::character varying, 'partially_refunded'::character varying, 'refunded'::character varying]::text[])", name: "chk_invoice_status_valid"
    t.check_constraint "subtotal_cents >= 0 AND tax_cents >= 0 AND total_cents >= 0 AND amount_paid_cents >= 0 AND amount_refunded_cents >= 0 AND amount_due_cents >= 0", name: "chk_invoice_amounts_positive"
    t.check_constraint "total_cents = (subtotal_cents + tax_cents)", name: "chk_invoice_total_calculation"
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

  create_table "subscriptions", comment: "Recurring billing subscriptions linking customers to pricing", force: :cascade do |t|
    t.string "subscription_id", null: false, comment: "External-facing subscription identifier (sub_xxx)"
    t.bigint "customer_id", null: false
    t.bigint "price_id", null: false
    t.string "status", default: "trialing", null: false, comment: "Current subscription status (trialing, active, past_due, canceled, paused)"
    t.date "current_period_start", null: false, comment: "Start date of current billing period"
    t.date "current_period_end", null: false, comment: "End date of current billing period"
    t.datetime "trial_start_at", comment: "When trial period began (if applicable)"
    t.datetime "trial_end_at", comment: "When trial period ends (if applicable)"
    t.datetime "cancel_at", comment: "Scheduled cancellation date (end of period)"
    t.datetime "canceled_at", comment: "Actual cancellation timestamp (when status changed to canceled)"
    t.date "next_billing_date", null: false, comment: "Next scheduled billing date"
    t.jsonb "metadata", default: {}, null: false, comment: "Flexible JSONB storage for custom subscription attributes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cancel_at"], name: "idx_subscriptions_cancel_at_pending", where: "((cancel_at IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["customer_id", "deleted_at"], name: "index_subscriptions_on_customer_id_and_deleted_at"
    t.index ["customer_id", "status"], name: "index_subscriptions_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["next_billing_date"], name: "idx_subscriptions_next_billing_active", where: "(((status)::text = ANY ((ARRAY['active'::character varying, 'trialing'::character varying])::text[])) AND (deleted_at IS NULL))"
    t.index ["price_id"], name: "index_subscriptions_on_price_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["subscription_id"], name: "index_subscriptions_on_subscription_id", unique: true
    t.index ["trial_end_at"], name: "idx_subscriptions_trial_end_active", where: "(((status)::text = 'trialing'::text) AND (deleted_at IS NULL))"
    t.check_constraint "current_period_end > current_period_start", name: "chk_subscription_period_order"
    t.check_constraint "next_billing_date >= current_period_end", name: "chk_subscription_billing_date_order"
    t.check_constraint "status::text = ANY (ARRAY['trialing'::character varying, 'active'::character varying, 'past_due'::character varying, 'canceled'::character varying, 'paused'::character varying]::text[])", name: "chk_subscription_status_valid"
  end

  add_foreign_key "invoice_line_items", "invoices", on_delete: :cascade
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "subscriptions"
  add_foreign_key "prices", "products"
  add_foreign_key "subscriptions", "customers"
  add_foreign_key "subscriptions", "prices"
end

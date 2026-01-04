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

ActiveRecord::Schema[8.0].define(version: 2026_01_04_220656) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", comment: "API keys for authentication - key_digest is hashed, never store plain text", force: :cascade do |t|
    t.string "key_id", null: false, comment: "Public part of the API key (sk_xxx)"
    t.string "key_digest", null: false, comment: "Bcrypt hash of the secret key - NEVER store plain text keys"
    t.string "role", null: false, comment: "Permission level (admin, finance, standard, read_only)"
    t.string "name", null: false, comment: "Human-readable name for this key"
    t.datetime "last_used_at", comment: "Last time this key was used for authentication"
    t.datetime "expires_at", comment: "When this key expires (null = never expires)"
    t.datetime "revoked_at", comment: "When this key was revoked (null = still active)"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_api_keys_on_expires_at"
    t.index ["key_id"], name: "idx_api_keys_active", where: "(revoked_at IS NULL)"
    t.index ["key_id"], name: "index_api_keys_on_key_id", unique: true
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
    t.index ["role"], name: "index_api_keys_on_role"
    t.check_constraint "name::text <> ''::text", name: "chk_api_key_name_not_empty"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'finance'::character varying, 'standard'::character varying, 'read_only'::character varying]::text[])", name: "chk_api_key_role_valid"
  end

  create_table "audit_events", comment: "Audit trail of all significant actions in the system", force: :cascade do |t|
    t.string "event_id", null: false, comment: "Unique audit event identifier (aud_xxx)"
    t.string "actor_type", null: false, comment: "Type of entity that performed the action (User, ApiKey, etc.)"
    t.bigint "actor_id", null: false, comment: "ID of the entity that performed the action"
    t.string "subject_type", null: false, comment: "Type of entity that was acted upon (Customer, Invoice, etc.)"
    t.bigint "subject_id", null: false, comment: "ID of the entity that was acted upon"
    t.string "action", null: false, comment: "Action performed (create, update, delete, view, export, login, logout)"
    t.jsonb "change_data", default: {}, null: false, comment: "Before/after values for the change"
    t.inet "ip_address", comment: "IP address from which the action was performed"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["actor_type", "actor_id", "created_at"], name: "idx_audit_events_actor_time"
    t.index ["actor_type", "actor_id"], name: "index_audit_events_on_actor"
    t.index ["actor_type", "actor_id"], name: "index_audit_events_on_actor_type_and_actor_id"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["event_id"], name: "index_audit_events_on_event_id", unique: true
    t.index ["subject_type", "subject_id", "created_at"], name: "idx_audit_events_subject_time"
    t.index ["subject_type", "subject_id"], name: "index_audit_events_on_subject"
    t.index ["subject_type", "subject_id"], name: "index_audit_events_on_subject_type_and_subject_id"
    t.check_constraint "action::text = ANY (ARRAY['create'::character varying, 'update'::character varying, 'delete'::character varying, 'view'::character varying, 'export'::character varying, 'login'::character varying, 'logout'::character varying]::text[])", name: "chk_audit_event_action_valid"
  end

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

  create_table "ledger_entries", comment: "Immutable financial ledger entries - NEVER UPDATE OR DELETE", force: :cascade do |t|
    t.string "entity_type", null: false, comment: "Type of entity this entry belongs to (Customer, Invoice, etc.)"
    t.bigint "entity_id", null: false, comment: "ID of the entity this entry belongs to"
    t.string "entry_type", null: false, comment: "Type of entry (credit, debit, refund, adjustment, fee)"
    t.bigint "amount_cents", null: false, comment: "Amount in cents (positive for credits, negative for debits)"
    t.string "currency", null: false, comment: "ISO 4217 currency code"
    t.string "idempotency_key", null: false, comment: "Unique key to prevent duplicate entries"
    t.jsonb "metadata", default: {}, null: false, comment: "Additional data about the ledger entry"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_ledger_entries_on_created_at"
    t.index ["currency"], name: "index_ledger_entries_on_currency"
    t.index ["entity_type", "entity_id", "created_at"], name: "idx_ledger_entries_entity_time"
    t.index ["entity_type", "entity_id", "currency"], name: "idx_ledger_entries_entity_currency"
    t.index ["entity_type", "entity_id"], name: "index_ledger_entries_on_entity"
    t.index ["entry_type"], name: "index_ledger_entries_on_entry_type"
    t.index ["idempotency_key"], name: "index_ledger_entries_on_idempotency_key", unique: true
    t.check_constraint "currency::text = ANY (ARRAY['usd'::character varying, 'eur'::character varying, 'gbp'::character varying, 'jpy'::character varying]::text[])", name: "chk_ledger_currency_valid"
    t.check_constraint "entry_type::text = ANY (ARRAY['credit'::character varying, 'debit'::character varying, 'refund'::character varying, 'adjustment'::character varying, 'fee'::character varying]::text[])", name: "chk_ledger_entry_type_valid"
    t.check_constraint "idempotency_key::text <> ''::text", name: "chk_ledger_idempotency_key_not_empty"
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

  create_table "refunds", comment: "Refunds issued against invoices", force: :cascade do |t|
    t.string "refund_id", null: false, comment: "External-facing refund identifier (re_xxx)"
    t.bigint "invoice_id", null: false
    t.bigint "amount_cents", null: false, comment: "Refund amount in cents (must not exceed invoice total)"
    t.string "currency", null: false
    t.string "status", default: "pending", null: false, comment: "Refund status (pending, succeeded, failed, canceled)"
    t.string "reason", comment: "Reason for the refund (e.g., 'requested_by_customer', 'duplicate')"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_refunds_on_created_at"
    t.index ["invoice_id", "status"], name: "index_refunds_on_invoice_id_and_status"
    t.index ["invoice_id"], name: "index_refunds_on_invoice_id"
    t.index ["refund_id"], name: "index_refunds_on_refund_id", unique: true
    t.index ["status"], name: "index_refunds_on_status"
    t.check_constraint "amount_cents > 0", name: "chk_refund_amount_positive"
    t.check_constraint "currency::text = ANY (ARRAY['usd'::character varying, 'eur'::character varying, 'gbp'::character varying, 'jpy'::character varying]::text[])", name: "chk_refund_currency_valid"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'succeeded'::character varying, 'failed'::character varying, 'canceled'::character varying]::text[])", name: "chk_refund_status_valid"
  end

  create_table "subscription_usage_summaries", comment: "Aggregated usage summaries by subscription, metric, and period", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.string "metric", null: false, comment: "Metric being tracked (e.g., 'api_calls', 'storage_gb')"
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.decimal "total_quantity", precision: 15, scale: 5, default: "0.0", null: false, comment: "Sum of all usage events for this subscription/metric/period"
    t.datetime "last_aggregated_at", comment: "Last time new events were added to this summary"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metric"], name: "index_subscription_usage_summaries_on_metric"
    t.index ["period_start", "period_end"], name: "idx_usage_summaries_period"
    t.index ["subscription_id", "metric", "period_start", "period_end"], name: "idx_usage_summaries_unique", unique: true
    t.index ["subscription_id"], name: "index_subscription_usage_summaries_on_subscription_id"
    t.check_constraint "period_end >= period_start", name: "chk_usage_summary_period_order"
    t.check_constraint "total_quantity >= 0::numeric", name: "chk_usage_summary_quantity_non_negative"
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

  create_table "usage_events", comment: "Individual usage events (API calls, storage, etc.) for metered billing", force: :cascade do |t|
    t.string "event_id", null: false, comment: "Unique event identifier for idempotency"
    t.bigint "subscription_id", null: false
    t.string "metric_name", null: false, comment: "Name of the metric being tracked (e.g., 'api_calls', 'storage_gb')"
    t.decimal "quantity", precision: 15, scale: 5, null: false, comment: "Quantity of usage (e.g., 1 API call, 2.5 GB storage)"
    t.datetime "timestamp", null: false, comment: "When the usage occurred (must be within last 24 hours)"
    t.datetime "processed_at", comment: "When this event was aggregated into subscription_usage_summaries"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_usage_events_on_event_id", unique: true
    t.index ["metric_name"], name: "index_usage_events_on_metric_name"
    t.index ["processed_at"], name: "idx_usage_events_unprocessed", where: "(processed_at IS NULL)"
    t.index ["subscription_id", "metric_name", "timestamp"], name: "idx_usage_events_sub_metric_time"
    t.index ["subscription_id"], name: "index_usage_events_on_subscription_id"
    t.index ["timestamp"], name: "index_usage_events_on_timestamp"
    t.check_constraint "\"timestamp\" >= (now() - 'PT24H'::interval)", name: "chk_usage_event_timestamp_recent"
    t.check_constraint "quantity > 0::numeric", name: "chk_usage_event_quantity_positive"
  end

  create_table "webhook_delivery_attempts", comment: "Individual delivery attempts of webhook events to endpoints", force: :cascade do |t|
    t.bigint "webhook_event_id", null: false
    t.bigint "webhook_endpoint_id", null: false
    t.integer "attempt_number", null: false, comment: "Attempt number for this event/endpoint combination (1, 2, 3...)"
    t.string "status", null: false, comment: "Status of this delivery attempt (pending, success, failed)"
    t.integer "response_code", comment: "HTTP response code from the endpoint"
    t.text "response_body", comment: "HTTP response body from the endpoint (truncated for storage)"
    t.datetime "attempted_at", null: false, comment: "When this delivery attempt was made"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempted_at"], name: "index_webhook_delivery_attempts_on_attempted_at"
    t.index ["status"], name: "index_webhook_delivery_attempts_on_status"
    t.index ["webhook_endpoint_id"], name: "index_webhook_delivery_attempts_on_webhook_endpoint_id"
    t.index ["webhook_event_id", "status"], name: "idx_webhook_attempts_failed", where: "((status)::text = 'failed'::text)"
    t.index ["webhook_event_id", "webhook_endpoint_id", "attempt_number"], name: "idx_webhook_attempts_unique", unique: true
    t.index ["webhook_event_id"], name: "index_webhook_delivery_attempts_on_webhook_event_id"
    t.check_constraint "attempt_number > 0", name: "chk_webhook_attempt_number_positive"
    t.check_constraint "response_code IS NULL OR response_code >= 100 AND response_code < 600", name: "chk_webhook_attempt_response_code_valid"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'success'::character varying, 'failed'::character varying]::text[])", name: "chk_webhook_attempt_status_valid"
  end

  create_table "webhook_endpoints", comment: "Webhook endpoints that receive event notifications", force: :cascade do |t|
    t.string "endpoint_id", null: false, comment: "External-facing endpoint identifier (we_xxx)"
    t.string "url", null: false, comment: "HTTPS URL to send webhook events to"
    t.string "secret_digest", null: false, comment: "Bcrypt hash of the webhook secret for signature verification"
    t.text "events", default: [], null: false, comment: "Array of event types this endpoint subscribes to", array: true
    t.boolean "active", default: true, null: false, comment: "Whether this endpoint is currently active"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_webhook_endpoints_on_active"
    t.index ["deleted_at"], name: "index_webhook_endpoints_on_deleted_at"
    t.index ["endpoint_id"], name: "index_webhook_endpoints_on_endpoint_id", unique: true
    t.check_constraint "url::text <> ''::text", name: "chk_webhook_endpoint_url_not_empty"
    t.check_constraint "url::text ~ '^https://'::text", name: "chk_webhook_endpoint_https_url"
  end

  create_table "webhook_events", comment: "Webhook events to be delivered to subscribed endpoints", force: :cascade do |t|
    t.string "event_id", null: false, comment: "Unique event identifier (evt_xxx)"
    t.string "event_type", null: false, comment: "Type of event (e.g., 'invoice.paid', 'subscription.created')"
    t.jsonb "payload", null: false, comment: "Event payload containing the actual event data"
    t.boolean "delivered", default: false, null: false, comment: "Whether this event has been successfully delivered to at least one endpoint"
    t.integer "attempts_count", default: 0, null: false, comment: "Total number of delivery attempts across all endpoints"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "idx_webhook_events_undelivered", where: "(delivered = false)"
    t.index ["created_at"], name: "index_webhook_events_on_created_at"
    t.index ["delivered"], name: "index_webhook_events_on_delivered"
    t.index ["event_id"], name: "index_webhook_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_webhook_events_on_event_type"
    t.check_constraint "attempts_count >= 0", name: "chk_webhook_event_attempts_non_negative"
  end

  add_foreign_key "invoice_line_items", "invoices", on_delete: :cascade
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "subscriptions"
  add_foreign_key "prices", "products"
  add_foreign_key "refunds", "invoices"
  add_foreign_key "subscription_usage_summaries", "subscriptions"
  add_foreign_key "subscriptions", "customers"
  add_foreign_key "subscriptions", "prices"
  add_foreign_key "usage_events", "subscriptions"
  add_foreign_key "webhook_delivery_attempts", "webhook_endpoints"
  add_foreign_key "webhook_delivery_attempts", "webhook_events"
end

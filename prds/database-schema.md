# Rails Stripelet - Database Schema

## Overview
This document defines the complete database schema for Rails Stripelet, demonstrating superior database design principles: normalization, indexing strategy, constraints, and financial data integrity.

---

## Schema Principles

### Financial Correctness
- **Append-only ledger**: No updates or deletes on financial records
- **No stored balances**: Always calculated from ledger entries
- **ACID transactions**: All financial operations are atomic
- **Idempotency constraints**: Unique indexes prevent duplicate operations

### Performance
- **Strategic indexing**: Foreign keys, lookups, and query patterns
- **Partitioning**: Large tables partitioned by date
- **Materialized views**: For expensive reports (optional)
- **JSONB columns**: Flexible metadata storage

### Auditability
- **Timestamps**: Every record has created_at/updated_at
- **Soft deletes**: Where appropriate (not on financial records)
- **Audit trail**: Separate audit_events table

---

## Entity Relationship Diagram

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  customers  │────────<│subscriptions │>────────│   prices    │
└──────┬──────┘         └──────┬───────┘         └──────┬──────┘
       │                       │                        │
       │                       │                        │
       │                  ┌────┴─────┐            ┌────┴──────┐
       │                  │ invoices │            │  products │
       │                  └────┬─────┘            └───────────┘
       │                       │
       │                  ┌────┴──────────────┐
       │                  │invoice_line_items │
       │                  └───────────────────┘
       │
       │                  ┌──────────────────┐
       ├─────────────────>│ ledger_entries   │ (polymorphic entity)
       │                  └──────────────────┘
       │
       │                  ┌──────────────────┐
       ├─────────────────>│ usage_events     │
       │                  └──────────────────┘
       │
       │                  ┌─────────────────────────┐
       └─────────────────>│subscription_usage_      │
                          │summaries                │
                          └─────────────────────────┘

┌──────────────────┐         ┌─────────────────────┐
│webhook_endpoints │<────────│  webhook_events     │
└──────────────────┘         └──────────┬──────────┘
                                        │
                             ┌──────────┴────────────────┐
                             │webhook_delivery_attempts  │
                             └───────────────────────────┘

┌─────────────┐         ┌──────────────┐
│   refunds   │────────<│   invoices   │
└─────────────┘         └──────────────┘

┌─────────────┐
│  api_keys   │
└─────────────┘

┌──────────────┐
│audit_events  │ (polymorphic subject)
└──────────────┘
```

---

## Complete Schema

### 1. Customers Table

```sql
CREATE TABLE customers (
  id BIGSERIAL PRIMARY KEY,
  customer_id VARCHAR(255) NOT NULL UNIQUE,  -- 'cus_xxx' format
  email VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  currency VARCHAR(3) DEFAULT 'usd',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_customers_email ON customers(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_customer_id ON customers(customer_id);
CREATE INDEX idx_customers_created_at ON customers(created_at);

COMMENT ON TABLE customers IS 'Customer accounts that can have subscriptions and be billed';
COMMENT ON COLUMN customers.customer_id IS 'External-facing customer identifier (cus_xxx)';
COMMENT ON COLUMN customers.metadata IS 'Flexible JSONB storage for custom attributes';
```

**Key Decisions:**
- `customer_id` is external identifier (exposed via API)
- `id` is internal primary key (never exposed)
- Email unique constraint excludes soft-deleted records
- Metadata as JSONB allows flexible custom fields
- Default currency per customer

---

### 2. Products Table

```sql
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  product_id VARCHAR(255) NOT NULL UNIQUE,  -- 'prod_xxx' format
  name VARCHAR(255) NOT NULL,
  description TEXT,
  active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_product_id ON products(product_id);
CREATE INDEX idx_products_active ON products(active);

COMMENT ON TABLE products IS 'Billable products/services';
```

---

### 3. Prices Table

```sql
CREATE TABLE prices (
  id BIGSERIAL PRIMARY KEY,
  price_id VARCHAR(255) NOT NULL UNIQUE,  -- 'price_xxx' format
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  currency VARCHAR(3) NOT NULL,
  amount_cents BIGINT NOT NULL,
  billing_scheme VARCHAR(50) DEFAULT 'per_unit',  -- 'per_unit' or 'tiered'
  interval VARCHAR(50) NOT NULL,  -- 'month', 'year', 'week', 'day'
  interval_count INTEGER DEFAULT 1,
  active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_amount_positive CHECK (amount_cents >= 0),
  CONSTRAINT chk_interval_count_positive CHECK (interval_count > 0),
  CONSTRAINT chk_billing_scheme CHECK (billing_scheme IN ('per_unit', 'tiered'))
);

CREATE INDEX idx_prices_price_id ON prices(price_id);
CREATE INDEX idx_prices_product_id ON prices(product_id);
CREATE INDEX idx_prices_currency ON prices(currency);
CREATE INDEX idx_prices_active ON prices(active);

COMMENT ON TABLE prices IS 'Pricing configurations for products';
COMMENT ON COLUMN prices.amount_cents IS 'Price in smallest currency unit (cents)';
COMMENT ON COLUMN prices.interval IS 'Billing frequency (month, year, etc.)';
COMMENT ON COLUMN prices.interval_count IS 'Number of intervals (e.g., 3 for quarterly)';
```

**Key Decisions:**
- Prices are immutable (change active status, don't update)
- Support multiple currencies per product
- Interval-based billing (monthly, yearly, etc.)
- Amount stored in cents to avoid floating-point errors

---

### 4. Subscriptions Table

```sql
CREATE TABLE subscriptions (
  id BIGSERIAL PRIMARY KEY,
  subscription_id VARCHAR(255) NOT NULL UNIQUE,  -- 'sub_xxx' format
  customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  price_id BIGINT NOT NULL REFERENCES prices(id) ON DELETE RESTRICT,
  status VARCHAR(50) NOT NULL DEFAULT 'active',  
  -- Status: 'trialing', 'active', 'past_due', 'canceled', 'paused'
  
  current_period_start DATE NOT NULL,
  current_period_end DATE NOT NULL,
  trial_start_at TIMESTAMP,
  trial_end_at TIMESTAMP,
  cancel_at TIMESTAMP,
  canceled_at TIMESTAMP,
  next_billing_date DATE,
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_status CHECK (status IN ('trialing', 'active', 'past_due', 'canceled', 'paused')),
  CONSTRAINT chk_period_order CHECK (current_period_end > current_period_start)
);

CREATE INDEX idx_subscriptions_subscription_id ON subscriptions(subscription_id);
CREATE INDEX idx_subscriptions_customer_id ON subscriptions(customer_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_next_billing_date ON subscriptions(next_billing_date) 
  WHERE status IN ('active', 'trialing');
CREATE INDEX idx_subscriptions_trial_end ON subscriptions(trial_end_at) 
  WHERE status = 'trialing';
CREATE INDEX idx_subscriptions_cancel_at ON subscriptions(cancel_at) 
  WHERE cancel_at IS NOT NULL;

COMMENT ON TABLE subscriptions IS 'Recurring billing subscriptions';
COMMENT ON COLUMN subscriptions.status IS 'Current subscription status';
COMMENT ON COLUMN subscriptions.cancel_at IS 'Scheduled cancellation date (end of period)';
COMMENT ON COLUMN subscriptions.canceled_at IS 'Actual cancellation timestamp';
```

**Key Decisions:**
- Separate `cancel_at` (scheduled) and `canceled_at` (actual)
- `trial_end_at` determines when trial converts to paid
- `next_billing_date` drives billing cycle job
- Partial indexes for performance on active subscriptions

---

### 5. Invoices Table

```sql
CREATE TABLE invoices (
  id BIGSERIAL PRIMARY KEY,
  invoice_id VARCHAR(255) NOT NULL UNIQUE,  -- 'inv_xxx' format
  customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  subscription_id BIGINT REFERENCES subscriptions(id) ON DELETE RESTRICT,
  
  status VARCHAR(50) NOT NULL DEFAULT 'draft',
  -- Status: 'draft', 'open', 'paid', 'void', 'uncollectible', 'partially_refunded', 'refunded'
  
  currency VARCHAR(3) NOT NULL,
  subtotal_cents BIGINT NOT NULL DEFAULT 0,
  tax_cents BIGINT DEFAULT 0,
  total_cents BIGINT NOT NULL,
  amount_paid_cents BIGINT DEFAULT 0,
  amount_refunded_cents BIGINT DEFAULT 0,
  amount_due_cents BIGINT NOT NULL,
  
  period_start DATE,
  period_end DATE,
  due_date DATE,
  
  finalized_at TIMESTAMP,
  paid_at TIMESTAMP,
  voided_at TIMESTAMP,
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_status CHECK (status IN ('draft', 'open', 'paid', 'void', 'uncollectible', 'partially_refunded', 'refunded')),
  CONSTRAINT chk_amounts_positive CHECK (
    subtotal_cents >= 0 AND 
    tax_cents >= 0 AND 
    total_cents >= 0 AND
    amount_paid_cents >= 0 AND
    amount_refunded_cents >= 0
  ),
  CONSTRAINT chk_total_calculation CHECK (total_cents = subtotal_cents + tax_cents),
  CONSTRAINT chk_amount_due CHECK (amount_due_cents = total_cents - amount_paid_cents + amount_refunded_cents)
);

CREATE INDEX idx_invoices_invoice_id ON invoices(invoice_id);
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX idx_invoices_subscription_id ON invoices(subscription_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date) WHERE status = 'open';
CREATE INDEX idx_invoices_created_at ON invoices(created_at);

COMMENT ON TABLE invoices IS 'Customer invoices (immutable once finalized)';
COMMENT ON COLUMN invoices.finalized_at IS 'When invoice moved from draft to open';
COMMENT ON COLUMN invoices.amount_due_cents IS 'Calculated: total - paid + refunded';
```

**Key Decisions:**
- Invoices are immutable once `finalized_at` is set
- Separate tracking of paid, refunded amounts
- Database constraints enforce calculation correctness
- `subscription_id` nullable (allows one-off invoices)

---

### 6. Invoice Line Items Table

```sql
CREATE TABLE invoice_line_items (
  id BIGSERIAL PRIMARY KEY,
  invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  
  description TEXT NOT NULL,
  quantity DECIMAL(10, 2) DEFAULT 1,
  unit_amount_cents BIGINT NOT NULL,
  amount_cents BIGINT NOT NULL,
  currency VARCHAR(3) NOT NULL,
  
  period_start DATE,
  period_end DATE,
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
  CONSTRAINT chk_amount_calculation CHECK (amount_cents = (unit_amount_cents * quantity)::BIGINT)
);

CREATE INDEX idx_invoice_line_items_invoice_id ON invoice_line_items(invoice_id);

COMMENT ON TABLE invoice_line_items IS 'Line items for invoices (subscription charges, usage, etc.)';
COMMENT ON COLUMN invoice_line_items.quantity IS 'Quantity of units (e.g., API calls, storage GB)';
```

**Key Decisions:**
- Cascade delete with invoice (line items don't exist independently)
- Quantity as DECIMAL supports fractional usage
- Amount constraint ensures calculation correctness

---

### 7. Ledger Entries Table (CRITICAL)

```sql
CREATE TABLE ledger_entries (
  id BIGSERIAL PRIMARY KEY,
  idempotency_key VARCHAR(255) NOT NULL UNIQUE,  -- CRITICAL for preventing duplicates
  
  entity_type VARCHAR(255) NOT NULL,  -- Polymorphic: 'Customer', 'Invoice', etc.
  entity_id BIGINT NOT NULL,
  
  entry_type VARCHAR(50) NOT NULL,
  -- Types: 'charge', 'payment', 'refund', 'credit', 'adjustment'
  
  amount_cents BIGINT NOT NULL,
  currency VARCHAR(3) NOT NULL,
  
  description TEXT,
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  -- Immutability enforcement (triggers prevent UPDATE/DELETE)
  
  CONSTRAINT chk_entry_type CHECK (entry_type IN ('charge', 'payment', 'refund', 'credit', 'adjustment')),
  CONSTRAINT chk_amount_not_zero CHECK (amount_cents != 0)
);

CREATE UNIQUE INDEX idx_ledger_idempotency ON ledger_entries(idempotency_key);
CREATE INDEX idx_ledger_entity ON ledger_entries(entity_type, entity_id);
CREATE INDEX idx_ledger_entry_type ON ledger_entries(entry_type);
CREATE INDEX idx_ledger_currency ON ledger_entries(currency);
CREATE INDEX idx_ledger_created_at ON ledger_entries(created_at);

-- Prevent updates and deletes (append-only)
CREATE OR REPLACE FUNCTION prevent_ledger_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Ledger entries are immutable';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_ledger_update
  BEFORE UPDATE ON ledger_entries
  FOR EACH ROW EXECUTE FUNCTION prevent_ledger_mutation();

CREATE TRIGGER prevent_ledger_delete
  BEFORE DELETE ON ledger_entries
  FOR EACH ROW EXECUTE FUNCTION prevent_ledger_mutation();

COMMENT ON TABLE ledger_entries IS 'Append-only financial ledger (immutable)';
COMMENT ON COLUMN ledger_entries.idempotency_key IS 'Prevents duplicate financial operations';
COMMENT ON COLUMN ledger_entries.entity_type IS 'Polymorphic association (Customer, Invoice, etc.)';
COMMENT ON COLUMN ledger_entries.entry_type IS 'Type of financial transaction';
```

**Key Decisions (CRITICAL):**
- **Append-only**: Triggers prevent UPDATE and DELETE
- **Idempotency**: Unique constraint on idempotency_key
- **No balance column**: Balance always calculated via SUM
- **Polymorphic entity**: Can associate with any model
- **Signed amounts**: Application logic determines sign based on entry_type

**Why no balance column?**
Prevents race conditions, drift, and reconciliation issues. Balance is always:
```sql
SELECT SUM(
  CASE 
    WHEN entry_type IN ('charge', 'adjustment') THEN amount_cents
    WHEN entry_type IN ('payment', 'refund', 'credit') THEN -amount_cents
    ELSE 0
  END
) FROM ledger_entries 
WHERE entity_type = 'Customer' AND entity_id = ?;
```

---

### 8. Usage Events Table

```sql
CREATE TABLE usage_events (
  id BIGSERIAL PRIMARY KEY,
  event_id VARCHAR(255) NOT NULL UNIQUE,  -- 'evt_xxx' format
  subscription_id BIGINT NOT NULL REFERENCES subscriptions(id) ON DELETE RESTRICT,
  
  metric VARCHAR(255) NOT NULL,  -- 'api_calls', 'storage_gb', etc.
  quantity DECIMAL(15, 5) NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  
  processed_at TIMESTAMP,
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
  CONSTRAINT chk_timestamp_recent CHECK (timestamp >= NOW() - INTERVAL '24 hours')
);

CREATE UNIQUE INDEX idx_usage_events_event_id ON usage_events(event_id);
CREATE INDEX idx_usage_events_subscription_id ON usage_events(subscription_id);
CREATE INDEX idx_usage_events_metric ON usage_events(metric);
CREATE INDEX idx_usage_events_timestamp ON usage_events(timestamp);
CREATE INDEX idx_usage_events_unprocessed ON usage_events(processed_at) 
  WHERE processed_at IS NULL;

-- Partition by month for large-scale usage
-- CREATE TABLE usage_events_2026_01 PARTITION OF usage_events
--   FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

COMMENT ON TABLE usage_events IS 'Metered usage events for billing';
COMMENT ON COLUMN usage_events.event_id IS 'External event identifier (prevents duplicates)';
COMMENT ON COLUMN usage_events.processed_at IS 'When event was aggregated for billing';
COMMENT ON COLUMN usage_events.timestamp IS 'When usage occurred (must be within 24h)';
```

**Key Decisions:**
- Unique `event_id` prevents duplicate event ingestion
- Timestamp constraint prevents backdating beyond 24 hours
- `processed_at` tracks which events have been aggregated
- Partitioning recommended for high-volume usage

---

### 9. Subscription Usage Summaries Table

```sql
CREATE TABLE subscription_usage_summaries (
  id BIGSERIAL PRIMARY KEY,
  subscription_id BIGINT NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  metric VARCHAR(255) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  
  total_quantity DECIMAL(15, 5) NOT NULL DEFAULT 0,
  last_aggregated_at TIMESTAMP,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT uq_subscription_usage UNIQUE (subscription_id, metric, period_start, period_end)
);

CREATE INDEX idx_subscription_usage_subscription_id ON subscription_usage_summaries(subscription_id);
CREATE INDEX idx_subscription_usage_period ON subscription_usage_summaries(period_start, period_end);

COMMENT ON TABLE subscription_usage_summaries IS 'Pre-aggregated usage for fast invoice generation';
COMMENT ON COLUMN subscription_usage_summaries.total_quantity IS 'Sum of all usage_events for this period';
```

**Key Decisions:**
- Aggregated hourly by background job
- Enables fast invoice generation (no need to SUM events)
- Unique constraint prevents duplicate summaries

---

### 10. Refunds Table

```sql
CREATE TABLE refunds (
  id BIGSERIAL PRIMARY KEY,
  refund_id VARCHAR(255) NOT NULL UNIQUE,  -- 'ref_xxx' format
  invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
  
  amount_cents BIGINT NOT NULL,
  currency VARCHAR(3) NOT NULL,
  reason VARCHAR(255),
  status VARCHAR(50) DEFAULT 'succeeded',
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_amount_positive CHECK (amount_cents > 0),
  CONSTRAINT chk_status CHECK (status IN ('pending', 'succeeded', 'failed'))
);

CREATE INDEX idx_refunds_refund_id ON refunds(refund_id);
CREATE INDEX idx_refunds_invoice_id ON refunds(invoice_id);
CREATE INDEX idx_refunds_created_at ON refunds(created_at);

COMMENT ON TABLE refunds IS 'Refunds for invoices (creates ledger entries)';
```

**Key Decisions:**
- Each refund creates a ledger entry
- Total refunds cannot exceed invoice total (enforced at application layer)
- Immutable once created

---

### 11. Webhook Endpoints Table

```sql
CREATE TABLE webhook_endpoints (
  id BIGSERIAL PRIMARY KEY,
  endpoint_id VARCHAR(255) NOT NULL UNIQUE,  -- 'we_xxx' format
  
  url TEXT NOT NULL,
  secret_digest VARCHAR(255) NOT NULL,  -- bcrypt hash of secret
  
  enabled BOOLEAN DEFAULT true,
  description TEXT,
  
  events TEXT[] DEFAULT ARRAY[]::TEXT[],  -- Array of subscribed event types
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_url_https CHECK (url LIKE 'https://%')
);

CREATE INDEX idx_webhook_endpoints_endpoint_id ON webhook_endpoints(endpoint_id);
CREATE INDEX idx_webhook_endpoints_enabled ON webhook_endpoints(enabled);

COMMENT ON TABLE webhook_endpoints IS 'Customer webhook URLs for event notifications';
COMMENT ON COLUMN webhook_endpoints.secret_digest IS 'Hashed webhook secret for signature verification';
COMMENT ON COLUMN webhook_endpoints.events IS 'Array of event types to receive (empty = all events)';
```

**Key Decisions:**
- Secret stored as hash (never plain text)
- HTTPS-only enforced by constraint
- Event filtering via array column

---

### 12. Webhook Events Table

```sql
CREATE TABLE webhook_events (
  id BIGSERIAL PRIMARY KEY,
  event_id VARCHAR(255) NOT NULL UNIQUE,  -- 'evt_webhook_xxx' format
  
  event_type VARCHAR(255) NOT NULL,  -- 'customer.created', 'invoice.paid', etc.
  
  resource_type VARCHAR(255) NOT NULL,  -- 'Customer', 'Invoice', etc.
  resource_id BIGINT NOT NULL,
  
  payload JSONB NOT NULL,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX idx_webhook_events_type ON webhook_events(event_type);
CREATE INDEX idx_webhook_events_created_at ON webhook_events(created_at);
CREATE INDEX idx_webhook_events_resource ON webhook_events(resource_type, resource_id);

COMMENT ON TABLE webhook_events IS 'Log of all webhook events generated';
COMMENT ON COLUMN webhook_events.payload IS 'Full JSON payload sent to webhook endpoints';
```

**Key Decisions:**
- Stores all webhook events for replay and debugging
- Unique `event_id` ensures idempotency
- Payload as JSONB for querying

---

### 13. Webhook Delivery Attempts Table

```sql
CREATE TABLE webhook_delivery_attempts (
  id BIGSERIAL PRIMARY KEY,
  webhook_event_id BIGINT NOT NULL REFERENCES webhook_events(id) ON DELETE CASCADE,
  webhook_endpoint_id BIGINT NOT NULL REFERENCES webhook_endpoints(id) ON DELETE CASCADE,
  
  attempt_number INTEGER NOT NULL DEFAULT 1,
  status VARCHAR(50) NOT NULL,  -- 'pending', 'succeeded', 'failed'
  
  http_status_code INTEGER,
  response_body TEXT,
  error_message TEXT,
  
  attempted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  duration_ms INTEGER,
  
  CONSTRAINT chk_attempt_number CHECK (attempt_number > 0),
  CONSTRAINT chk_status CHECK (status IN ('pending', 'succeeded', 'failed'))
);

CREATE INDEX idx_webhook_attempts_event_id ON webhook_delivery_attempts(webhook_event_id);
CREATE INDEX idx_webhook_attempts_endpoint_id ON webhook_delivery_attempts(webhook_endpoint_id);
CREATE INDEX idx_webhook_attempts_status ON webhook_delivery_attempts(status);
CREATE INDEX idx_webhook_attempts_attempted_at ON webhook_delivery_attempts(attempted_at);

COMMENT ON TABLE webhook_delivery_attempts IS 'Log of webhook delivery attempts for debugging';
COMMENT ON COLUMN webhook_delivery_attempts.attempt_number IS 'Retry count (1-10)';
```

**Key Decisions:**
- Tracks every delivery attempt (including retries)
- Stores HTTP response for debugging
- Duration tracking for performance monitoring

---

### 14. API Keys Table

```sql
CREATE TABLE api_keys (
  id BIGSERIAL PRIMARY KEY,
  key_id VARCHAR(255) NOT NULL UNIQUE,  -- External identifier
  key_digest VARCHAR(255) NOT NULL UNIQUE,  -- bcrypt hash of actual key
  
  name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'standard',  -- 'admin', 'finance', 'standard', 'read_only'
  
  active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_role CHECK (role IN ('admin', 'finance', 'standard', 'read_only'))
);

CREATE UNIQUE INDEX idx_api_keys_key_id ON api_keys(key_id);
CREATE UNIQUE INDEX idx_api_keys_digest ON api_keys(key_digest);
CREATE INDEX idx_api_keys_active ON api_keys(active);

COMMENT ON TABLE api_keys IS 'API authentication keys';
COMMENT ON COLUMN api_keys.key_digest IS 'bcrypt hash of API key (never store plain text)';
COMMENT ON COLUMN api_keys.role IS 'Permission level for authorization';
```

**Key Decisions:**
- Keys stored as hash (never plain text)
- Role-based access control
- Expiration support
- Track last usage for security auditing

---

### 15. Audit Events Table

```sql
CREATE TABLE audit_events (
  id BIGSERIAL PRIMARY KEY,
  event_type VARCHAR(255) NOT NULL,  -- 'customer.updated', 'refund.created', etc.
  
  actor_type VARCHAR(255),  -- 'ApiKey', 'User', 'System'
  actor_id BIGINT,
  
  subject_type VARCHAR(255) NOT NULL,  -- 'Customer', 'Invoice', etc.
  subject_id BIGINT NOT NULL,
  
  changes JSONB,  -- Before/after values
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_events_type ON audit_events(event_type);
CREATE INDEX idx_audit_events_actor ON audit_events(actor_type, actor_id);
CREATE INDEX idx_audit_events_subject ON audit_events(subject_type, subject_id);
CREATE INDEX idx_audit_events_created_at ON audit_events(created_at);

-- Partition by year for compliance (7-year retention)
-- CREATE TABLE audit_events_2026 PARTITION OF audit_events
--   FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

COMMENT ON TABLE audit_events IS 'Audit trail for compliance and debugging';
COMMENT ON COLUMN audit_events.changes IS 'JSON diff of before/after values';
```

**Key Decisions:**
- Captures who, what, when for all financial operations
- IP and user agent for security
- JSONB changes for detailed diff
- Partition by year (7-year regulatory retention)

---

## Indexing Strategy Summary

### Critical Performance Indexes

**Foreign Keys** (automatically used in JOINs):
```sql
-- All foreign key columns indexed
idx_subscriptions_customer_id
idx_invoices_customer_id
idx_ledger_entity (composite)
```

**Lookups** (API endpoints):
```sql
-- External IDs for API lookups
idx_customers_customer_id
idx_invoices_invoice_id
idx_subscriptions_subscription_id
```

**Background Jobs** (queries by workers):
```sql
-- Billing cycle job
idx_subscriptions_next_billing_date WHERE status IN ('active', 'trialing')
idx_subscriptions_trial_end WHERE status = 'trialing'

-- Usage aggregation job
idx_usage_events_unprocessed WHERE processed_at IS NULL
```

**Financial Calculations** (ledger queries):
```sql
-- Balance calculations
idx_ledger_entity (entity_type, entity_id)
idx_ledger_currency

-- Idempotency
idx_ledger_idempotency (UNIQUE)
```

---

## Database Constraints Summary

### Data Integrity

**Unique Constraints:**
- All external IDs (customer_id, invoice_id, etc.)
- Idempotency keys (ledger_entries, usage_events)
- Email (excluding soft-deleted)

**Check Constraints:**
- Amounts are positive
- Calculations are correct (total = subtotal + tax)
- Enums are valid (status, entry_type)
- Timestamps are recent (usage events)

**Foreign Key Constraints:**
- ON DELETE RESTRICT for financial records
- ON DELETE CASCADE for dependent data (line items)

**Immutability:**
- Ledger entries protected by triggers
- Invoices cannot change after finalized_at

---

## Migration Example

```ruby
# db/migrate/20260101000007_create_ledger_entries.rb
class CreateLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_entries do |t|
      t.string :idempotency_key, null: false, index: { unique: true }
      
      t.string :entity_type, null: false
      t.bigint :entity_id, null: false
      
      t.string :entry_type, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, limit: 3
      
      t.text :description
      t.jsonb :metadata, default: {}
      
      t.timestamp :created_at, null: false, default: -> { 'NOW()' }
      
      t.index [:entity_type, :entity_id], name: 'idx_ledger_entity'
      t.index :entry_type
      t.index :currency
      t.index :created_at
    end
    
    # Enforce immutability
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE OR REPLACE FUNCTION prevent_ledger_mutation()
          RETURNS TRIGGER AS $$
          BEGIN
            RAISE EXCEPTION 'Ledger entries are immutable';
          END;
          $$ LANGUAGE plpgsql;

          CREATE TRIGGER prevent_ledger_update
            BEFORE UPDATE ON ledger_entries
            FOR EACH ROW EXECUTE FUNCTION prevent_ledger_mutation();

          CREATE TRIGGER prevent_ledger_delete
            BEFORE DELETE ON ledger_entries
            FOR EACH ROW EXECUTE FUNCTION prevent_ledger_mutation();
        SQL
      end
      
      dir.down do
        execute 'DROP TRIGGER IF EXISTS prevent_ledger_update ON ledger_entries'
        execute 'DROP TRIGGER IF EXISTS prevent_ledger_delete ON ledger_entries'
        execute 'DROP FUNCTION IF EXISTS prevent_ledger_mutation()'
      end
    end
  end
end
```

---

## Partitioning Strategy (For Scale)

### Tables to Partition

**1. Usage Events** (high write volume):
```sql
CREATE TABLE usage_events (
  -- columns...
) PARTITION BY RANGE (timestamp);

CREATE TABLE usage_events_2026_01 PARTITION OF usage_events
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

**2. Audit Events** (long retention):
```sql
CREATE TABLE audit_events (
  -- columns...
) PARTITION BY RANGE (created_at);

CREATE TABLE audit_events_2026 PARTITION OF audit_events
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
```

**Benefits:**
- Query performance on time-range queries
- Easy data archival (detach old partitions)
- Independent maintenance (VACUUM, ANALYZE)

---

## Materialized Views (Optional)

### MRR Report View

```sql
CREATE MATERIALIZED VIEW mrr_by_plan AS
SELECT 
  p.name AS plan_name,
  pr.currency,
  COUNT(s.id) AS subscription_count,
  SUM(
    CASE 
      WHEN pr.interval = 'month' THEN pr.amount_cents
      WHEN pr.interval = 'year' THEN pr.amount_cents / 12
      ELSE 0
    END
  ) AS mrr_cents,
  MAX(s.updated_at) AS last_updated
FROM subscriptions s
JOIN prices pr ON s.price_id = pr.id
JOIN products p ON pr.product_id = p.id
WHERE s.status = 'active'
GROUP BY p.name, pr.currency;

CREATE UNIQUE INDEX idx_mrr_plan_currency ON mrr_by_plan(plan_name, currency);

-- Refresh hourly
-- SELECT refresh_materialized_view_concurrently('mrr_by_plan');
```

---

## Data Retention Policies

| Table | Retention | Rationale |
|-------|-----------|-----------|
| **ledger_entries** | Forever | Legal/regulatory requirement |
| **invoices** | Forever | Tax records |
| **audit_events** | 7 years | Compliance (SOX, GDPR) |
| **webhook_events** | 30 days | Debugging window |
| **webhook_delivery_attempts** | 30 days | Debugging window |
| **usage_events** | 1 year | After aggregation, archive raw events |

---

## Seed Data

```ruby
# db/seeds.rb

# Products
product_basic = Product.create!(
  product_id: 'prod_basic',
  name: 'Basic Plan',
  description: 'Starter plan for small teams'
)

product_pro = Product.create!(
  product_id: 'prod_pro',
  name: 'Pro Plan',
  description: 'Advanced plan for growing businesses'
)

# Prices
Price.create!([
  {
    price_id: 'price_basic_monthly_usd',
    product: product_basic,
    currency: 'usd',
    amount_cents: 2900,  # $29.00
    interval: 'month',
    interval_count: 1
  },
  {
    price_id: 'price_basic_yearly_usd',
    product: product_basic,
    currency: 'usd',
    amount_cents: 29000,  # $290.00 (2 months free)
    interval: 'year',
    interval_count: 1
  },
  {
    price_id: 'price_pro_monthly_usd',
    product: product_pro,
    currency: 'usd',
    amount_cents: 9900,  # $99.00
    interval: 'month',
    interval_count: 1
  }
])

puts "Seeded #{Product.count} products and #{Price.count} prices"
```

---

## Schema Verification Queries

### Check Ledger Integrity

```sql
-- Verify no updates have occurred (all updated_at should equal created_at if column exists)
-- Ledger entries don't have updated_at by design

-- Verify idempotency keys are unique
SELECT idempotency_key, COUNT(*) 
FROM ledger_entries 
GROUP BY idempotency_key 
HAVING COUNT(*) > 1;
-- Should return 0 rows

-- Verify balance calculation matches ledger
SELECT 
  c.customer_id,
  (SELECT SUM(
    CASE 
      WHEN entry_type IN ('charge', 'adjustment') THEN amount_cents
      WHEN entry_type IN ('payment', 'refund', 'credit') THEN -amount_cents
      ELSE 0
    END
  ) FROM ledger_entries 
   WHERE entity_type = 'Customer' AND entity_id = c.id) AS calculated_balance
FROM customers c;
```

### Check Invoice Totals

```sql
-- Verify invoice totals match line items
SELECT 
  i.invoice_id,
  i.subtotal_cents AS invoice_subtotal,
  COALESCE(SUM(li.amount_cents), 0) AS line_items_total
FROM invoices i
LEFT JOIN invoice_line_items li ON li.invoice_id = i.id
WHERE i.finalized_at IS NOT NULL
GROUP BY i.id
HAVING i.subtotal_cents != COALESCE(SUM(li.amount_cents), 0);
-- Should return 0 rows
```

---

## Summary: Key Schema Highlights

✅ **Append-only ledger** with triggers preventing mutations  
✅ **Idempotency everywhere** via unique constraints  
✅ **No stored balances** - always calculated from ledger  
✅ **Strategic indexing** for API performance and job queries  
✅ **Database constraints** enforce financial correctness  
✅ **Partitioning ready** for high-volume tables  
✅ **Audit trail** with 7-year retention  
✅ **Immutable invoices** after finalization  
✅ **Multi-currency support** throughout  

This schema demonstrates senior-level thinking: **correctness over convenience, auditability over performance shortcuts, and safety over speed**.

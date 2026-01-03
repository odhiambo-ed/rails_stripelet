# Rails Stripelet - User Stories

## Overview
This document outlines user stories for Rails Stripelet, organized by user persona and feature area. Each story includes acceptance criteria and technical notes demonstrating senior-level considerations.

---

## Personas

### 1. **API Consumer** (Developer integrating with Rails Stripelet)
External developers building applications that need billing functionality.

### 2. **End Customer** (Business using the billing system)
Companies using Rails Stripelet to manage their subscriptions and billing.

### 3. **Platform Administrator** (Internal user managing the system)
Operations team monitoring system health and managing customer accounts.

### 4. **Finance Team** (Accounting and reconciliation)
Users who need accurate financial reports and audit trails.

---

## Epic 1: Customer Management

### Story 1.1: Create Customer via API
**As an** API Consumer  
**I want to** create a customer account via API  
**So that** I can start billing them for services

**Acceptance Criteria:**
- [ ] POST `/api/v1/customers` with name, email, metadata
- [ ] Returns 201 with customer object including unique `customer_id`
- [ ] Email is validated and unique
- [ ] Idempotent: same request twice returns same customer
- [ ] Rate limited to prevent abuse (100 req/min per API key)
- [ ] Responds within 200ms (p95)

**Technical Notes:**
- Idempotency key in header: `Idempotency-Key: <uuid>`
- Store idempotency mappings for 24 hours
- Customer ID format: `cus_<nanoid(21)>`

**Example Request:**
```bash
curl -X POST https://api.stripelet.com/v1/customers \
  -H "Authorization: Bearer sk_test_xxx" \
  -H "Idempotency-Key: req_123abc" \
  -d "email=john@example.com" \
  -d "name=John Doe" \
  -d "metadata[user_id]=12345"
```

---

### Story 1.2: Retrieve Customer Balance
**As an** API Consumer  
**I want to** fetch a customer's current balance  
**So that** I can display it in my application

**Acceptance Criteria:**
- [ ] GET `/api/v1/customers/:id/balance`
- [ ] Returns balance calculated from ledger (not stored)
- [ ] Includes breakdown: charges, payments, refunds
- [ ] Supports multi-currency (returns all balances)
- [ ] Cached for 5 minutes to reduce DB load
- [ ] Returns 404 if customer not found

**Technical Notes:**
- Balance derived via: `SUM(ledger_entries.amount_cents) WHERE entity_id = customer.id`
- Cache key: `customer:#{id}:balance:#{cache_version}`
- Invalidate cache on new ledger entry

**Example Response:**
```json
{
  "customer_id": "cus_abc123",
  "balances": [
    {
      "currency": "usd",
      "amount_cents": 15000,
      "breakdown": {
        "charges": 20000,
        "payments": -5000,
        "refunds": 0
      }
    }
  ],
  "as_of": "2026-01-03T19:00:00Z"
}
```

---

### Story 1.3: Update Customer Metadata
**As an** API Consumer  
**I want to** update customer metadata without affecting billing  
**So that** I can store custom business context

**Acceptance Criteria:**
- [ ] PATCH `/api/v1/customers/:id`
- [ ] Only allows updating: name, email, metadata
- [ ] Does not allow changing: id, created_at, balance
- [ ] Metadata is JSONB (flexible schema)
- [ ] Audit log records who made the change
- [ ] Returns 200 with updated customer

**Technical Notes:**
- Use strong params to prevent mass assignment
- Metadata limited to 10KB to prevent abuse
- Emit `customer.updated` webhook event

---

## Epic 2: Subscription Management

### Story 2.1: Create Subscription with Trial
**As an** API Consumer  
**I want to** create a subscription with a trial period  
**So that** customers can test before paying

**Acceptance Criteria:**
- [ ] POST `/api/v1/subscriptions` with customer_id, price_id, trial_days
- [ ] Subscription status is `trialing`
- [ ] No invoice generated during trial
- [ ] Trial end date calculated and stored
- [ ] Background job scheduled for trial end
- [ ] Webhook `subscription.created` sent asynchronously
- [ ] Returns 201 immediately (async billing)

**Technical Notes:**
- Trial end: `created_at + trial_days.days`
- Enqueue `SubscriptionTrialEndJob` for trial_end_at
- Subscription ID format: `sub_<nanoid(21)>`

**Example Request:**
```json
{
  "customer_id": "cus_abc123",
  "price_id": "price_pro_monthly",
  "trial_days": 14,
  "metadata": {
    "plan": "pro",
    "source": "website"
  }
}
```

---

### Story 2.2: Handle Trial End with Billing
**As a** Platform Administrator  
**I want** trials to automatically convert to paid subscriptions  
**So that** billing happens without manual intervention

**Acceptance Criteria:**
- [ ] `BillingCycleJob` runs daily at 00:00 UTC
- [ ] Finds subscriptions where `trial_end_at <= now` and status is `trialing`
- [ ] Generates first invoice
- [ ] Creates ledger entries for charges
- [ ] Updates subscription status to `active`
- [ ] Sends `subscription.trial_ended` and `invoice.created` webhooks
- [ ] Idempotent: safe to run multiple times

**Technical Notes:**
- Use advisory locks to prevent duplicate processing
- Idempotency key: `trial_end:#{subscription.id}:#{trial_end_at.to_i}`
- Retry on failure with exponential backoff

---

### Story 2.3: Upgrade Subscription with Proration
**As an** API Consumer  
**I want to** upgrade a subscription mid-cycle  
**So that** customers can access higher tier features immediately

**Acceptance Criteria:**
- [ ] POST `/api/v1/subscriptions/:id/upgrade` with new_price_id
- [ ] Calculates unused time on current plan
- [ ] Credits prorated amount
- [ ] Charges new plan amount
- [ ] Creates ledger entries for both credit and charge
- [ ] Updates subscription immediately
- [ ] Generates proration invoice
- [ ] Webhook sent asynchronously

**Technical Notes:**
- Proration formula: `(days_remaining / days_in_period) * old_price`
- Both credit and charge use same idempotency key
- Transaction ensures atomic update

**Example Calculation:**
```ruby
# Old plan: $100/month, 20 days remaining out of 30
credit = (20.0 / 30.0) * 10000  # 6667 cents
charge = 15000  # New plan: $150/month
net_charge = charge - credit    # 8333 cents
```

---

### Story 2.4: Cancel Subscription (End of Period)
**As an** API Consumer  
**I want to** cancel a subscription at the end of the billing period  
**So that** customers can finish their paid term

**Acceptance Criteria:**
- [ ] POST `/api/v1/subscriptions/:id/cancel` with `cancel_at_period_end: true`
- [ ] Subscription remains `active` until period end
- [ ] No refund issued
- [ ] `cancel_at` timestamp set to period end
- [ ] Customer retains access until `cancel_at`
- [ ] Status changes to `canceled` via scheduled job
- [ ] Webhook `subscription.canceled` sent on actual cancellation

**Technical Notes:**
- Do not delete subscription record (audit trail)
- `BillingCycleJob` checks for `cancel_at <= now`
- No new renewals after cancellation

---

### Story 2.5: Cancel Subscription (Immediate with Refund)
**As an** API Consumer  
**I want to** cancel a subscription immediately with prorated refund  
**So that** customers get refunded for unused time

**Acceptance Criteria:**
- [ ] POST `/api/v1/subscriptions/:id/cancel` with `cancel_immediately: true`
- [ ] Calculates prorated refund
- [ ] Creates refund ledger entry
- [ ] Updates subscription status to `canceled`
- [ ] Generates refund invoice
- [ ] Enqueues webhook job
- [ ] Returns 200 with cancellation details

**Technical Notes:**
- Refund calculation: `(days_remaining / days_in_period) * amount_paid`
- Idempotency key: `cancel:#{subscription.id}:#{Time.now.to_i}`
- Transaction: update subscription + create ledger entry

---

## Epic 3: Invoicing

### Story 3.1: Generate Monthly Invoice
**As a** Platform Administrator  
**I want** invoices to be generated automatically  
**So that** billing is consistent and timely

**Acceptance Criteria:**
- [ ] `BillingCycleJob` runs daily
- [ ] Finds subscriptions with `next_billing_date <= today`
- [ ] Aggregates line items (subscription + metered usage)
- [ ] Creates invoice with `draft` status
- [ ] Calculates totals including tax (if applicable)
- [ ] Appends ledger entries
- [ ] Finalizes invoice (status: `open`)
- [ ] Sends `invoice.created` webhook

**Technical Notes:**
- Invoice ID format: `inv_<nanoid(21)>`
- Line items stored as JSONB for flexibility
- Invoice is immutable once finalized

**Invoice Structure:**
```json
{
  "invoice_id": "inv_xyz789",
  "customer_id": "cus_abc123",
  "status": "open",
  "amount_due_cents": 15000,
  "currency": "usd",
  "line_items": [
    {
      "description": "Pro Plan (Jan 2026)",
      "amount_cents": 10000,
      "quantity": 1
    },
    {
      "description": "API Calls (15,000 calls @ $0.01)",
      "amount_cents": 5000,
      "quantity": 15000
    }
  ],
  "period_start": "2026-01-01",
  "period_end": "2026-01-31"
}
```

---

### Story 3.2: View Invoice as PDF
**As an** End Customer  
**I want to** download invoices as PDF  
**So that** I can share them with my finance team

**Acceptance Criteria:**
- [ ] GET `/api/v1/invoices/:id/pdf`
- [ ] Returns PDF with company branding
- [ ] Includes: invoice number, line items, totals, payment terms
- [ ] PDF generated asynchronously (not on-demand)
- [ ] Cached for 24 hours
- [ ] Returns 404 if invoice not finalized

**Technical Notes:**
- Use `wicked_pdf` or `prawn` gem
- Generate PDF in background job when invoice finalized
- Store in cloud storage (S3-compatible)

---

### Story 3.3: Mark Invoice as Paid
**As a** Platform Administrator  
**I want** to manually mark an invoice as paid  
**So that** I can reconcile offline payments

**Acceptance Criteria:**
- [ ] POST `/api/v1/invoices/:id/pay` with payment_method
- [ ] Creates payment ledger entry
- [ ] Updates invoice status to `paid`
- [ ] Updates customer balance
- [ ] Sends `invoice.paid` webhook
- [ ] Idempotent: calling twice doesn't double-pay

**Technical Notes:**
- Idempotency key required
- Payment ledger entry: `entry_type: 'payment'`
- Audit log records who marked it paid

---

## Epic 4: Metered Usage Billing

### Story 4.1: Report Usage Events
**As an** API Consumer  
**I want to** report usage events in real-time  
**So that** customers are billed accurately for consumption

**Acceptance Criteria:**
- [ ] POST `/api/v1/usage_events` with subscription_id, metric, quantity, timestamp
- [ ] Accepts bulk upload (up to 1000 events)
- [ ] Returns 202 Accepted (async processing)
- [ ] Events stored with unique constraint on `event_id`
- [ ] Deduplication via idempotency key
- [ ] Rate limited to 1000 req/min

**Technical Notes:**
- Event ID format: `evt_<nanoid(21)>`
- Timestamp must be within 24 hours (prevent backdating)
- Store events in partitioned table for performance

**Example Request:**
```json
{
  "events": [
    {
      "event_id": "evt_api_call_123",
      "subscription_id": "sub_abc",
      "metric": "api_calls",
      "quantity": 150,
      "timestamp": "2026-01-03T18:00:00Z"
    }
  ]
}
```

---

### Story 4.2: Aggregate Usage for Billing
**As a** Platform Administrator  
**I want** usage to be aggregated hourly  
**So that** near-real-time usage data is available

**Acceptance Criteria:**
- [ ] `UsageAggregationJob` runs every hour
- [ ] Groups events by subscription + metric
- [ ] Sums quantities for billing period
- [ ] Updates `subscription_usage_summaries` table
- [ ] Handles late-arriving events (up to 24h old)
- [ ] Idempotent: safe to re-run

**Technical Notes:**
- Use `processed_at IS NULL` to find new events
- Mark events as processed atomically
- Summary table enables fast lookups

---

### Story 4.3: Include Usage in Invoice
**As a** Finance Team Member  
**I want** usage charges to appear on invoices  
**So that** customers see detailed billing breakdown

**Acceptance Criteria:**
- [ ] When generating invoice, fetch usage summaries
- [ ] Calculate charge: `quantity * unit_price`
- [ ] Add line item to invoice
- [ ] Include usage period in description
- [ ] Reset usage counter for new period
- [ ] Append ledger entry for usage charge

**Technical Notes:**
- Pricing stored in `prices` table with `billing_scheme: 'per_unit'`
- Support tiered pricing (future enhancement)

---

## Epic 5: Webhooks

### Story 5.1: Configure Webhook Endpoint
**As an** API Consumer  
**I want to** register a webhook URL  
**So that** I receive real-time event notifications

**Acceptance Criteria:**
- [ ] POST `/api/v1/webhook_endpoints` with url, events[]
- [ ] Validates URL is HTTPS
- [ ] Returns webhook secret for signature verification
- [ ] Allows filtering by event types
- [ ] Supports multiple endpoints per account
- [ ] Returns 201 with endpoint details

**Technical Notes:**
- Secret format: `whsec_<random_64_chars>`
- Store secret hashed (bcrypt)
- Endpoint ID format: `we_<nanoid(21)>`

**Example Request:**
```json
{
  "url": "https://example.com/webhooks",
  "events": [
    "customer.created",
    "invoice.created",
    "invoice.paid"
  ],
  "description": "Production webhook"
}
```

---

### Story 5.2: Receive Webhook with Signature Verification
**As an** API Consumer  
**I want** webhooks to be signed  
**So that** I can verify they came from Rails Stripelet

**Acceptance Criteria:**
- [ ] Webhook includes header: `Stripelet-Signature: t=<timestamp>,v1=<signature>`
- [ ] Signature computed via HMAC-SHA256
- [ ] Timestamp within 5 minutes to prevent replay attacks
- [ ] Consumer verifies signature before processing
- [ ] Documentation includes verification examples

**Technical Notes:**
- Signing algorithm: `HMAC-SHA256(timestamp + '.' + payload, webhook_secret)`
- Include timestamp to prevent replay attacks

**Verification Example (Ruby):**
```ruby
def verify_webhook(payload, signature_header, secret)
  timestamp, signature = parse_header(signature_header)
  
  # Check timestamp freshness
  return false if Time.now.to_i - timestamp.to_i > 300
  
  # Compute expected signature
  signed_payload = "#{timestamp}.#{payload}"
  expected = OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)
  
  # Constant-time comparison
  ActiveSupport::SecurityUtils.secure_compare(expected, signature)
end
```

---

### Story 5.3: Retry Failed Webhooks
**As a** Platform Administrator  
**I want** failed webhooks to retry automatically  
**So that** transient failures don't lose events

**Acceptance Criteria:**
- [ ] `WebhookDeliveryJob` retries up to 10 times
- [ ] Exponential backoff: 3s, 9s, 27s, 81s...
- [ ] Timeout after 30 seconds per attempt
- [ ] After 10 failures, move to dead-letter queue
- [ ] Dashboard shows failed deliveries
- [ ] Manual replay available

**Technical Notes:**
- Store delivery attempts in `webhook_delivery_attempts` table
- Log HTTP status code, response body, timing
- Alert on high failure rate

---

### Story 5.4: View Webhook Event Log
**As an** API Consumer  
**I want to** see webhook delivery history  
**So that** I can debug integration issues

**Acceptance Criteria:**
- [ ] GET `/api/v1/webhook_events` with pagination
- [ ] Shows: event type, payload, delivery status, timestamps
- [ ] Filterable by event type, date range, status
- [ ] Includes response codes and timing
- [ ] Supports replay of individual events
- [ ] Retained for 30 days

**Technical Notes:**
- Partition table by month for performance
- Archive old events to cold storage

---

## Epic 6: Refunds & Credits

### Story 6.1: Issue Full Refund
**As an** API Consumer  
**I want to** issue a full refund for an invoice  
**So that** customers can receive their money back

**Acceptance Criteria:**
- [ ] POST `/api/v1/refunds` with invoice_id, reason
- [ ] Creates negative ledger entry
- [ ] Updates invoice status to `refunded`
- [ ] Decreases customer balance
- [ ] Enqueues `RefundProcessingJob`
- [ ] Sends `refund.created` webhook
- [ ] Idempotent via idempotency key

**Technical Notes:**
- Refund ID format: `ref_<nanoid(21)>`
- Ledger entry: `entry_type: 'refund', amount_cents: -original_amount`
- Cannot refund more than invoice total

---

### Story 6.2: Issue Partial Refund
**As an** API Consumer  
**I want to** issue a partial refund  
**So that** I can refund specific line items

**Acceptance Criteria:**
- [ ] POST `/api/v1/refunds` with invoice_id, amount_cents, reason
- [ ] Validates amount <= invoice total
- [ ] Creates ledger entry for partial amount
- [ ] Invoice status becomes `partially_refunded`
- [ ] Tracks total refunded amount
- [ ] Multiple partial refunds allowed (up to total)

**Technical Notes:**
- Check: `invoice.refunded_amount + new_refund <= invoice.total`
- Use transaction to ensure atomicity

---

### Story 6.3: Apply Account Credit
**As a** Platform Administrator  
**I want to** apply credit to customer account  
**So that** I can compensate for service issues

**Acceptance Criteria:**
- [ ] POST `/api/v1/customers/:id/credits` with amount_cents, reason
- [ ] Creates positive ledger entry (decreases balance due)
- [ ] Credit applied to next invoice automatically
- [ ] Visible on customer balance breakdown
- [ ] Audit trail of who issued credit
- [ ] Sends `customer.credit_applied` webhook

**Technical Notes:**
- Ledger entry: `entry_type: 'credit', amount_cents: negative value`
- Credits never expire
- Used automatically at invoice generation

---

## Epic 7: Revenue Reporting

### Story 7.1: View Monthly Recurring Revenue (MRR)
**As a** Finance Team Member  
**I want to** see MRR broken down by plan  
**So that** I can track business growth

**Acceptance Criteria:**
- [ ] GET `/api/v1/reports/mrr` returns MRR metrics
- [ ] Grouped by plan type
- [ ] Shows: current MRR, new MRR, churned MRR, expansion MRR
- [ ] Filterable by date range
- [ ] Exportable as CSV
- [ ] Cached and updated daily

**Technical Notes:**
- MRR = SUM(active subscriptions where interval='month')
- New MRR = subscriptions created this month
- Churned MRR = subscriptions canceled this month
- Expansion MRR = upgrades - downgrades

---

### Story 7.2: Generate Revenue Recognition Report
**As a** Finance Team Member  
**I want** revenue recognized over subscription period  
**So that** I comply with accounting standards (ASC 606)

**Acceptance Criteria:**
- [ ] GET `/api/v1/reports/revenue_recognition`
- [ ] Shows earned vs deferred revenue
- [ ] Calculated based on subscription period
- [ ] Monthly breakdown
- [ ] Exportable for accounting software
- [ ] Auditable with ledger references

**Technical Notes:**
- Deferred revenue = prepaid but not yet earned
- Recognize revenue daily: `invoice_amount / days_in_period`
- Create `revenue_recognition_schedule` table

---

### Story 7.3: Export Transaction Ledger
**As a** Finance Team Member  
**I want to** export complete ledger as CSV  
**So that** I can reconcile in external systems

**Acceptance Criteria:**
- [ ] GET `/api/v1/reports/ledger.csv`
- [ ] Includes all ledger entries with metadata
- [ ] Filterable by date range, customer, entry type
- [ ] Shows: timestamp, entity, amount, currency, type, description
- [ ] Immutable: matches database exactly
- [ ] Large exports processed asynchronously

**Technical Notes:**
- Use background job for exports > 10,000 rows
- Email download link when ready
- Signed URL expires in 1 hour

---

## Epic 8: Multi-Currency Support

### Story 8.1: Create Price in Multiple Currencies
**As an** API Consumer  
**I want to** define prices in different currencies  
**So that** I can bill customers in their local currency

**Acceptance Criteria:**
- [ ] POST `/api/v1/prices` with currency, amount_cents
- [ ] Supports ISO 4217 currency codes (USD, EUR, GBP, etc.)
- [ ] Same product can have multiple currency prices
- [ ] Subscription uses customer's preferred currency
- [ ] No automatic currency conversion

**Technical Notes:**
- Store amounts as integers (cents)
- Use `money-rails` gem for currency handling
- Price ID format: `price_<product>_<currency>_<interval>`

---

### Story 8.2: Display Balance in Native Currency
**As an** API Consumer  
**I want** customer balance in original currencies  
**So that** I avoid conversion rounding errors

**Acceptance Criteria:**
- [ ] Customer can have balances in multiple currencies
- [ ] Each currency tracked separately
- [ ] No forced conversion to base currency
- [ ] Invoices always in single currency
- [ ] Balance endpoint returns array of currency balances

**Technical Notes:**
- Ledger entry includes `currency` column
- Group by currency when calculating balance
- Dashboard shows all currencies

---

## Epic 9: Security & Compliance

### Story 9.1: Rate Limit API Requests
**As a** Platform Administrator  
**I want** API requests rate limited  
**So that** system remains stable under load

**Acceptance Criteria:**
- [ ] 1000 requests per minute per API key
- [ ] Returns `429 Too Many Requests` when exceeded
- [ ] Response includes `Retry-After` header
- [ ] Different limits for different endpoints
- [ ] Bypass rate limiting for webhooks (internal)

**Technical Notes:**
- Use Redis + Rack::Attack gem
- Sliding window algorithm
- Whitelist for testing

---

### Story 9.2: Audit Log for Financial Changes
**As a** Finance Team Member  
**I want** all financial changes logged  
**So that** we have compliance audit trail

**Acceptance Criteria:**
- [ ] Every ledger entry includes: who, when, why
- [ ] Immutable audit log (append-only)
- [ ] Includes IP address, user agent, API key used
- [ ] Searchable by customer, date, amount, type
- [ ] Retained for 7 years (regulatory requirement)
- [ ] Exportable for auditors

**Technical Notes:**
- Use `paper_trail` gem for model auditing
- Separate `audit_events` table
- Partition by year for performance

---

### Story 9.3: Implement Role-Based Access Control
**As a** Platform Administrator  
**I want** different permission levels  
**So that** team members have appropriate access

**Acceptance Criteria:**
- [ ] Roles: admin, finance, support, read-only
- [ ] Admin: full access
- [ ] Finance: view reports, issue refunds
- [ ] Support: view customers, cannot modify billing
- [ ] Read-only: dashboard access only
- [ ] API keys scoped to roles

**Technical Notes:**
- Use `pundit` gem for authorization
- Policy objects for each resource
- API key includes role scope

---

## Non-Functional Requirements

### Performance
- [ ] API response time p95 < 200ms
- [ ] Balance calculation < 100ms (with caching)
- [ ] Webhook delivery < 5s (p95)
- [ ] Support 10,000 req/min

### Reliability
- [ ] 99.9% uptime SLA
- [ ] Zero data loss (ACID transactions)
- [ ] Automatic job retries
- [ ] Dead-letter queue for manual review

### Security
- [ ] HTTPS only
- [ ] API key authentication
- [ ] Webhook signature verification
- [ ] Rate limiting
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS protection (API-only, no HTML rendering)

### Scalability
- [ ] Horizontal scaling via load balancer
- [ ] Database read replicas for reports
- [ ] Background job workers scale independently
- [ ] Caching layer (Redis)

### Maintainability
- [ ] Test coverage > 90%
- [ ] API versioning (/v1, /v2)
- [ ] Semantic versioning
- [ ] Comprehensive API documentation
- [ ] Runnable via Docker Compose locally

---

## Story Prioritization

### Phase 1 (MVP - Week 1-2)
1. Customer CRUD
2. Subscription create/cancel
3. Basic invoicing
4. Ledger service
5. Webhook delivery

### Phase 2 (Core Features - Week 3-4)
1. Metered usage billing
2. Proration logic
3. Refunds
4. Webhook signature verification
5. Multi-currency

### Phase 3 (Polish - Week 5-6)
1. Revenue reports
2. PDF invoices
3. Dashboard UI (Next.js)
4. Audit logs
5. Role-based access

### Phase 4 (Production Ready - Week 7-8)
1. Rate limiting
2. Comprehensive tests
3. Documentation
4. Docker deployment
5. Monitoring & alerts

---

## Definition of Done

A story is complete when:
- [ ] Code implemented and passes linting
- [ ] Unit tests written (>80% coverage for critical paths)
- [ ] Integration tests for API endpoints
- [ ] Property-based tests for financial logic
- [ ] API documentation updated
- [ ] Manual testing in dev environment
- [ ] Code reviewed
- [ ] No critical security vulnerabilities
- [ ] Performance meets SLA (<200ms)
- [ ] Database migrations are reversible
- [ ] Idempotency verified
- [ ] Webhook events implemented

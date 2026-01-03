# Rails Stripelet - Design Architecture

## Overview
Rails Stripelet is a production-grade billing system demonstrating superior architectural patterns for financial applications. This document outlines the architectural decisions, tradeoffs, and design patterns that ensure financial correctness, auditability, and scalability.

---

## Core Architectural Principles

### 1. **Clear Separation of Sync API vs Async Billing**

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Requests                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   Rails API Layer (Sync)                     │
│  - Request validation                                        │
│  - Authentication/Authorization                              │
│  - Immediate operations (create customer, fetch invoice)    │
│  - Enqueue async jobs                                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├──────────────┬──────────────────────┐
                  ▼              ▼                      ▼
┌─────────────────────┐ ┌────────────────┐ ┌──────────────────────┐
│   Database          │ │  Sidekiq Queue │ │  Response to Client  │
│   (Immediate Write) │ │  (Async Jobs)  │ │  (201/200 status)    │
└─────────────────────┘ └────────┬───────┘ └──────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────────┐
                    │   Sidekiq Workers (Async)  │
                    │  - Billing calculations    │
                    │  - Invoice generation      │
                    │  - Webhook delivery        │
                    │  - Usage aggregation       │
                    │  - Subscription renewals   │
                    └────────────┬───────────────┘
                                 │
                                 ▼
                    ┌────────────────────────────┐
                    │  Ledger Service (Write)    │
                    │  Webhook Service (Send)    │
                    └────────────────────────────┘
```

**Why this separation?**
- **Sync Layer**: Fast API responses (<200ms), immediate feedback to clients
- **Async Layer**: Complex calculations, billing cycles, external API calls
- **Failure Isolation**: API stays responsive even if billing jobs fail
- **Scalability**: Async workers scale independently from API servers

---

### 2. **Ledger Isolated from UI Concerns**

```
┌────────────────────────────────────────────────────────────────┐
│                        Application Layer                       │
│                                                                 │
│  ┌──────────────────┐        ┌─────────────────────┐          │
│  │  API Controllers │        │  Admin Dashboard    │          │
│  │  (External API)  │        │  (Internal UI)      │          │
│  └────────┬─────────┘        └──────────┬──────────┘          │
│           │                              │                     │
│           └──────────────┬───────────────┘                     │
│                          │                                     │
│                          ▼                                     │
│           ┌──────────────────────────────┐                    │
│           │    Business Logic Layer      │                    │
│           │  - BillingService            │                    │
│           │  - SubscriptionService       │                    │
│           │  - InvoiceService            │                    │
│           └──────────────┬───────────────┘                    │
│                          │                                     │
│                          ▼                                     │
│           ┌──────────────────────────────┐                    │
│           │     Ledger Service Layer     │                    │
│           │  (Financial Correctness)     │                    │
│           │                               │                    │
│           │  - append_entry(params)      │                    │
│           │  - calculate_balance(entity) │                    │
│           │  - idempotent_transaction()  │                    │
│           └──────────────┬───────────────┘                    │
│                          │                                     │
└──────────────────────────┼─────────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   ledger_entries       │
              │   (Append-Only)        │
              │                        │
              │  - id                  │
              │  - idempotency_key     │
              │  - entity_type/id      │
              │  - amount_cents        │
              │  - currency            │
              │  - entry_type          │
              │  - metadata (jsonb)    │
              │  - created_at          │
              └────────────────────────┘
```

**Key Points:**
- UI/API never writes directly to ledger
- All financial operations go through LedgerService
- Ledger is a pure append-only log
- Balance is always calculated, never stored
- Presentation layer reads but never mutates financial data

---

### 3. **Sidekiq Handles Retries, Billing Cycles, and Webhooks**

```
┌─────────────────────────────────────────────────────────────┐
│                      Sidekiq Job Types                      │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────┐
│ BillingCycleJob          │  Scheduled: Daily @ 00:00 UTC
│ (sidekiq-cron)           │  
│                          │  - Find subscriptions due for renewal
│ Retry: 25 attempts       │  - Generate invoices
│ Backoff: exponential     │  - Calculate prorations
└──────────────────────────┘

┌──────────────────────────┐
│ WebhookDeliveryJob       │  Triggered: On events
│                          │  
│ Retry: 10 attempts       │  - Verify signature
│ Backoff: exponential     │  - HTTP POST to customer endpoint
│ Timeout: 30s             │  - Log response
└──────────────────────────┘

┌──────────────────────────┐
│ UsageAggregationJob      │  Scheduled: Hourly
│                          │  
│ Retry: 15 attempts       │  - Aggregate metered usage
│ Backoff: exponential     │  - Calculate charges
└──────────────────────────┘

┌──────────────────────────┐
│ RefundProcessingJob      │  Triggered: On refund request
│                          │  
│ Retry: 20 attempts       │  - Create ledger entries
│ Backoff: exponential     │  - Update invoice status
│                          │  - Trigger webhook
└──────────────────────────┘

┌──────────────────────────┐
│ Dead Letter Queue        │  Failed jobs after all retries
│                          │  
│ - Manual investigation   │  - Alert engineering team
│ - Replay capability      │  - Audit trail
└──────────────────────────┘
```

**Retry Strategy:**
- Exponential backoff: 3s, 9s, 27s, 81s...
- Maximum retry window: 21 days
- Dead-letter queue for manual intervention
- All jobs are idempotent by design

---

## Idempotent Webhook Handling

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Webhook Flow                             │
└─────────────────────────────────────────────────────────────┘

  External System                Rails Stripelet
  (e.g., Customer)              
       │
       │ POST /webhooks/events
       │ Headers: Signature, Timestamp
       │ Body: { event_id, type, data }
       │
       ▼
┌──────────────────────────┐
│ WebhooksController       │
│                          │
│ 1. Verify signature      │──── FAIL ──► 401 Unauthorized
│ 2. Check timestamp       │──── FAIL ──► 400 Expired
│ 3. Parse payload         │──── FAIL ──► 422 Invalid
└──────────┬───────────────┘
           │
           │ PASS
           ▼
┌──────────────────────────┐
│ webhook_events table     │
│                          │
│ INSERT (idempotency_key) │
│ ON CONFLICT DO NOTHING   │──── Already processed ──► 200 OK (duplicate)
└──────────┬───────────────┘
           │
           │ New event
           ▼
┌──────────────────────────┐
│ WebhookProcessorJob      │
│ .perform_async(event_id) │──── Enqueued ──► 202 Accepted
└──────────┬───────────────┘
           │
           ▼
    [Async Processing]
           │
           ▼
┌──────────────────────────┐
│ WebhookProcessorJob      │
│                          │
│ 1. Lock event record     │
│ 2. Check if processed    │──── Already done ──► Skip (idempotent)
│ 3. Process event         │
│ 4. Mark as processed     │
│ 5. Release lock          │
└──────────────────────────┘
```

**Idempotency Guarantees:**
1. **Database Constraint**: Unique index on `webhook_events(idempotency_key)`
2. **Processing Lock**: Advisory locks or status column
3. **Retry Safety**: Jobs check processed status before executing
4. **Duplicate Detection**: Same event_id returns 200 without reprocessing

---

## Async Processing Patterns

### Event-Driven Billing Lifecycle

```
Subscription Created
    │
    ├──► Immediate: Save to DB (sync)
    │
    └──► Async: 
         ├──► Send webhook to customer
         ├──► Schedule first billing date
         └──► Create initial invoice (if applicable)

Trial Ending
    │
    └──► BillingCycleJob detects trial end
         │
         ├──► Generate invoice
         ├──► Process payment
         ├──► Update subscription status
         └──► Send webhooks

Subscription Renewal
    │
    └──► BillingCycleJob (daily)
         │
         ├──► Find due subscriptions
         ├──► Calculate prorations
         ├──► Generate invoices
         ├──► Append ledger entries
         └──► Trigger webhooks

Usage Billing
    │
    └──► UsageAggregationJob (hourly)
         │
         ├──► Sum metered usage
         ├──► Calculate charges
         ├──► Append to next invoice
         └──► Update usage records
```

---

## Immutable Financial Records

### Append-Only Ledger Design

```sql
-- NEVER DO THIS (mutable balance)
UPDATE accounts SET balance = balance + 100 WHERE id = 123;

-- ALWAYS DO THIS (append-only)
INSERT INTO ledger_entries (
  entity_type, entity_id, 
  amount_cents, entry_type, 
  idempotency_key, metadata
) VALUES (
  'Customer', 123,
  10000, 'charge',
  'charge_xyz_20260103', 
  '{"invoice_id": 456}'::jsonb
);
```

**Benefits:**
- Complete audit trail
- Point-in-time balance reconstruction
- Safe concurrent operations
- Regulatory compliance
- Easy debugging and reconciliation

**Balance Calculation:**
```ruby
# Always derived, never stored
def calculate_balance(customer_id)
  LedgerEntry.where(entity_type: 'Customer', entity_id: customer_id)
             .sum('CASE 
                    WHEN entry_type IN (\'charge\', \'fee\') THEN amount_cents
                    WHEN entry_type IN (\'payment\', \'refund\') THEN -amount_cents
                    ELSE 0
                  END')
end
```

---

## Replay-Safe Design

### Characteristics of Replay Safety

1. **Idempotency Keys Everywhere**
   ```ruby
   # Every financial operation requires an idempotency key
   LedgerService.append_entry(
     idempotency_key: "inv_#{invoice.id}_charge_#{Time.now.to_i}",
     entity: customer,
     amount: invoice.amount,
     entry_type: :charge
   )
   ```

2. **Database Constraints**
   ```sql
   CREATE UNIQUE INDEX idx_ledger_idempotency 
   ON ledger_entries(idempotency_key);
   
   CREATE UNIQUE INDEX idx_webhook_events_key
   ON webhook_events(event_id);
   ```

3. **Service Object Pattern**
   ```ruby
   class BillingService
     def charge_subscription(subscription, idempotency_key:)
       # Check if already processed
       return if already_processed?(idempotency_key)
       
       # Atomic transaction
       ActiveRecord::Base.transaction do
         invoice = create_invoice(subscription)
         append_ledger_entry(invoice, idempotency_key)
         enqueue_webhook(invoice)
       end
     rescue ActiveRecord::RecordNotUnique
       # Idempotency key collision - already processed
       Rails.logger.info "Duplicate operation: #{idempotency_key}"
     end
   end
   ```

---

## Failure Points & Mitigation

### Where Things Can Fail

| Failure Point | Impact | Mitigation |
|--------------|--------|------------|
| **Database connection lost** | API requests fail | Connection pooling, retry logic, health checks |
| **Sidekiq worker crash** | Jobs not processed | Automatic retry, dead-letter queue, monitoring |
| **External webhook timeout** | Customer not notified | Exponential backoff, 30s timeout, retry 10x |
| **Race condition on billing** | Duplicate charges | Idempotency keys, database locks, unique constraints |
| **Invalid currency conversion** | Incorrect amounts | Validate at API layer, use Money gem, store original currency |
| **Proration calculation error** | Customer overcharged | Property-based tests, manual review queue, refund policy |
| **Webhook signature invalid** | Security breach | Reject immediately, log incident, alert team |

### Defense in Depth

```
┌─────────────────────────────────────────────────────┐
│ Layer 1: API Validation                             │
│ - Strong params, type checking, business rules      │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│ Layer 2: Service Objects                            │
│ - Idempotency checks, transaction boundaries        │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│ Layer 3: Database Constraints                       │
│ - Unique indexes, foreign keys, check constraints   │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│ Layer 4: Background Job Retries                     │
│ - Exponential backoff, dead-letter queue            │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│ Layer 5: Monitoring & Alerts                        │
│ - Error tracking, metrics, on-call rotation         │
└─────────────────────────────────────────────────────┘
```

---

## Tradeoffs & Alternatives Considered

### 1. **Append-Only Ledger vs Stored Balances**

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Stored Balance** | Fast reads, simple queries | Race conditions, drift, audit gaps | ❌ Not chosen |
| **Append-Only Ledger** | Audit trail, no drift, safe concurrent writes | Slower balance calculation, more storage | ✅ **Chosen** |

**Rationale**: Financial correctness > performance. Balance queries are cached and infrequent.

---

### 2. **Sync vs Async Billing**

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Synchronous Billing** | Immediate feedback, simpler code | Slow API responses, blocking operations | ❌ Not chosen |
| **Async Billing** | Fast API, scalable, failure isolation | Eventual consistency, more complexity | ✅ **Chosen** |

**Rationale**: Billing calculations can take seconds. Users need fast API responses.

---

### 3. **Microservices vs Monolith**

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Microservices** | Independent scaling, team autonomy | Network latency, distributed transactions | ❌ Not for MVP |
| **Modular Monolith** | Simple deployment, ACID transactions, fast | Shared database, must scale vertically first | ✅ **Chosen** |

**Rationale**: Start with monolith, extract services only when needed. Financial transactions benefit from ACID guarantees.

---

### 4. **Direct Payment Processing vs Mock**

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Stripe Integration** | Real payment processing | API costs, compliance burden | ❌ Not for portfolio |
| **Mock Payment Gateway** | Demonstrate architecture, no costs | Not production-ready | ✅ **Chosen** |

**Rationale**: Portfolio project focuses on architecture, not actual payment processing.

---

## Technology Choices

### Backend Stack
- **Rails 8 (API-only)**: Mature ecosystem, Active Record, strong conventions
- **PostgreSQL 17**: ACID compliance, JSONB support, advisory locks
- **Sidekiq**: Reliable background jobs, retries, cron scheduling
- **Redis**: Sidekiq queue, caching, rate limiting

### Frontend Stack
- **Next.js 14**: React framework, SSR, API routes
- **TypeScript**: Type safety for financial data
- **TailwindCSS**: Rapid UI development
- **shadcn/ui**: Accessible components

### Testing
- **RSpec**: Unit tests, request specs
- **FactoryBot**: Test data
- **rspec-propcheck**: Property-based testing for financial logic
- **VCR**: Record HTTP interactions

---

## Diagrams Summary

### System Context
```
┌──────────┐         ┌─────────────────┐         ┌────────────┐
│ Customer │────────▶│ Rails Stripelet │────────▶│ PostgreSQL │
│   App    │         │   (API + Jobs)  │         │  Database  │
└──────────┘         └────────┬────────┘         └────────────┘
                              │
                              │ webhooks
                              ▼
                     ┌────────────────┐
                     │ Customer Webhook│
                     │   Endpoints     │
                     └────────────────┘
```

### Data Flow
```
Request ──► API ──► Validation ──► DB Write ──► Enqueue Job ──► Response (202)
                                         │
                                         ▼
                            Sidekiq Worker ──► Ledger Service ──► DB Append
                                         │
                                         ▼
                            Webhook Delivery ──► Customer Endpoint
```

---

## Questions to Address in Implementation

### What tables do I need?
See `database-schema.md` for complete schema.

### Where do things fail?
1. Database connection
2. Sidekiq worker crashes
3. External webhooks timeout
4. Race conditions
5. Invalid data at API boundary

### What tradeoffs exist?
1. Append-only (auditability) vs stored balance (speed)
2. Async (scalability) vs sync (simplicity)
3. Monolith (ACID) vs microservices (scaling)
4. Strict idempotency (safety) vs eventual consistency (performance)

---

## Next Steps
1. Implement core models (see `database-schema.md`)
2. Build LedgerService with idempotency
3. Create Sidekiq jobs with retry logic
4. Set up webhook signing and verification
5. Add comprehensive tests (unit + property-based)
6. Build Next.js dashboard
7. Docker Compose for local development

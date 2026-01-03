# Rails Stripelet - Implementation Checklist
## From First Line of Code to Production Deployment

> **Track your progress from zero to deployed billing system**

---

## 📋 How to Use This Checklist

- [ ] Check off items as you complete them
- [ ] Work sequentially - each phase builds on the previous
- [ ] Don't skip tests - they catch bugs early
- [ ] Commit after each major milestone
- [ ] Deploy early and often (once you hit MVP)

---

## Phase 1: Project Foundation (Week 1)

### Environment Setup
- [ ] Install Ruby 3.3+
- [ ] Install PostgreSQL 17+
- [ ] Install Redis 7+
- [ ] Install Docker & Docker Compose
- [ ] Set up code editor (VS Code/RubyMine)
- [ ] Install essential gems (bundler, rails, etc.)

### Initial Rails Setup
- [ ] Create new Rails 8 API-only app: `rails new rails_stripelet --api --database=postgresql`
- [ ] Configure database.yml for development/test/production
- [ ] Set up Git repository
- [ ] Create .gitignore (include .env, logs, tmp)
- [ ] Create initial README.md
- [ ] First commit: "Initial Rails setup"

### Docker Configuration
- [ ] Create Dockerfile (multi-stage build)
- [ ] Create docker-compose.yml (web, db, redis, sidekiq)
- [ ] Create .dockerignore
- [ ] Test: `docker-compose up` works
- [ ] Test: `docker-compose exec web rails console` works

### Dependencies
- [ ] Add gems to Gemfile:
  - [ ] `pg` (PostgreSQL)
  - [ ] `redis`
  - [ ] `sidekiq`
  - [ ] `sidekiq-cron`
  - [ ] `rack-cors` (API CORS)
  - [ ] `rack-attack` (rate limiting)
  - [ ] `pundit` (authorization)
  - [ ] `bcrypt` (password hashing)
- [ ] Add test gems:
  - [ ] `rspec-rails`
  - [ ] `factory_bot_rails`
  - [ ] `faker`
  - [ ] `database_cleaner-active_record`
  - [ ] `shoulda-matchers`
  - [ ] `rspec-propcheck` (property-based testing)
  - [ ] `simplecov` (coverage)
- [ ] Run `bundle install`
- [ ] Initialize RSpec: `rails generate rspec:install`
- [ ] Configure SimpleCov in spec_helper.rb

### Database Setup
- [ ] Create databases: `rails db:create`
- [ ] Verify connection to PostgreSQL
- [ ] Configure database connection pooling
- [ ] Set up schema.rb for version control

**Milestone 1**: ✅ Development environment ready, Docker running, tests passing

---

## Phase 2: Core Database Schema (Week 1)

### Customer & Account Tables
- [ ] Migration: Create customers table
  - [ ] Add all columns (id, customer_id, email, name, currency, metadata, timestamps)
  - [ ] Add unique constraints (customer_id, email where deleted_at IS NULL)
  - [ ] Add indexes (customer_id, email, created_at)
  - [ ] Add check constraints
- [ ] Migration: Create products table
  - [ ] Columns, constraints, indexes
- [ ] Migration: Create prices table
  - [ ] Columns with currency support
  - [ ] Foreign key to products
  - [ ] Constraints for amount_cents > 0
- [ ] Run migrations: `rails db:migrate`
- [ ] Verify schema.rb is correct

### Subscription & Billing Tables
- [ ] Migration: Create subscriptions table
  - [ ] Status enum column
  - [ ] Trial dates (trial_start_at, trial_end_at)
  - [ ] Billing dates (current_period_start, current_period_end, next_billing_date)
  - [ ] Foreign keys to customers and prices
  - [ ] Partial indexes on status
- [ ] Migration: Create invoices table
  - [ ] Status enum
  - [ ] Amount columns (subtotal, tax, total, paid, refunded, due)
  - [ ] Timestamps (finalized_at, paid_at, voided_at)
  - [ ] Check constraints for calculations
- [ ] Migration: Create invoice_line_items table
  - [ ] Foreign key to invoices (cascade delete)
  - [ ] Amount calculation constraint

### Financial Ledger (CRITICAL)
- [ ] Migration: Create ledger_entries table
  - [ ] Polymorphic entity (entity_type, entity_id)
  - [ ] Entry type enum
  - [ ] Amount in cents (BIGINT)
  - [ ] Currency code
  - [ ] Idempotency key (UNIQUE)
  - [ ] Metadata JSONB
  - [ ] NO updated_at column (immutable)
- [ ] Migration: Add ledger immutability triggers
  - [ ] Create prevent_ledger_mutation() function
  - [ ] Add BEFORE UPDATE trigger
  - [ ] Add BEFORE DELETE trigger
  - [ ] Test: Attempt UPDATE should fail
  - [ ] Test: Attempt DELETE should fail

### Usage & Events Tables
- [ ] Migration: Create usage_events table
  - [ ] Unique event_id
  - [ ] Subscription reference
  - [ ] Metric name and quantity
  - [ ] Timestamp (with 24-hour constraint)
  - [ ] processed_at for aggregation tracking
- [ ] Migration: Create subscription_usage_summaries table
  - [ ] Unique constraint on (subscription_id, metric, period_start, period_end)

### Webhook Tables
- [ ] Migration: Create webhook_endpoints table
  - [ ] URL with HTTPS constraint
  - [ ] Secret digest (bcrypt hashed)
  - [ ] Events array (TEXT[])
- [ ] Migration: Create webhook_events table
  - [ ] Unique event_id
  - [ ] Event type and payload JSONB
- [ ] Migration: Create webhook_delivery_attempts table
  - [ ] Foreign keys to events and endpoints
  - [ ] Attempt tracking (number, status, response)

### Refunds & API Keys
- [ ] Migration: Create refunds table
  - [ ] Foreign key to invoices
  - [ ] Amount and status
- [ ] Migration: Create api_keys table
  - [ ] Key digest (hashed, not plain text)
  - [ ] Role enum (admin, finance, standard, read_only)
  - [ ] Expiration support
- [ ] Migration: Create audit_events table
  - [ ] Polymorphic actor and subject
  - [ ] Changes JSONB
  - [ ] IP address tracking

### Critical Database Triggers
- [ ] Migration: Invoice finalization lock trigger
  - [ ] Create prevent_finalized_invoice_mutation() function
  - [ ] Add BEFORE UPDATE trigger
  - [ ] Add BEFORE DELETE trigger
  - [ ] Test: Finalized invoices cannot be modified
- [ ] Migration: Refund validation trigger
  - [ ] Create validate_refund_amount() function
  - [ ] Add BEFORE INSERT trigger
  - [ ] Test: Cannot refund more than invoice total
- [ ] Migration: Subscription status validation trigger
  - [ ] Create validate_subscription_status_transition() function
  - [ ] Add BEFORE UPDATE trigger
  - [ ] Test: Invalid transitions rejected
- [ ] Migration: Advisory lock function
  - [ ] Create acquire_subscription_billing_lock() function

### Performance Indexes
- [ ] Migration: Add composite indexes
  - [ ] ledger_entries (entity_type, entity_id, currency)
  - [ ] subscriptions (status, next_billing_date) WHERE status = 'active'
  - [ ] usage_events (processed_at) WHERE processed_at IS NULL
- [ ] Verify EXPLAIN ANALYZE on key queries

### Seed Data
- [ ] Create db/seeds.rb
  - [ ] 2-3 products (Basic, Pro, Enterprise)
  - [ ] 6-8 prices (monthly/yearly for each product)
  - [ ] Test data for development
- [ ] Run: `rails db:seed`

**Milestone 2**: ✅ Complete database schema with triggers, all migrations passing

---

## Phase 3: Core Models (Week 2)

### Model Setup
- [ ] Generate models (skip migrations - already created):
  - [ ] `rails g model Customer --skip-migration`
  - [ ] `rails g model Product --skip-migration`
  - [ ] `rails g model Price --skip-migration`
  - [ ] `rails g model Subscription --skip-migration`
  - [ ] `rails g model Invoice --skip-migration`
  - [ ] `rails g model InvoiceLineItem --skip-migration`
  - [ ] `rails g model Ledger::Entry --skip-migration`
  - [ ] `rails g model UsageEvent --skip-migration`
  - [ ] `rails g model Refund --skip-migration`
  - [ ] `rails g model WebhookEndpoint --skip-migration`
  - [ ] `rails g model WebhookEvent --skip-migration`
  - [ ] `rails g model ApiKey --skip-migration`

### Model: Customer
- [ ] Add validations (email format, presence)
- [ ] Add associations (has_many subscriptions, invoices, ledger_entries)
- [ ] Add enum for currency (if not using string)
- [ ] Add method: `balance(currency = 'usd')`
- [ ] Add concern: Identifiable (generates customer_id before_create)
- [ ] Write specs: validations, associations, balance calculation

### Model: Product
- [ ] Validations (name presence)
- [ ] Associations (has_many prices)
- [ ] Active scope
- [ ] Write specs

### Model: Price
- [ ] Validations (amount_cents > 0, valid interval)
- [ ] Associations (belongs_to product)
- [ ] Enum: interval (month, year, week, day)
- [ ] Enum: billing_scheme (per_unit, tiered)
- [ ] Scope: active
- [ ] Write specs

### Model: Subscription
- [ ] Validations
- [ ] Associations (belongs_to customer, price)
- [ ] Enum: status (trialing, active, past_due, canceled, paused)
- [ ] Scopes: active, trialing, due_for_renewal
- [ ] Method: `in_trial?`
- [ ] Method: `days_until_renewal`
- [ ] Callbacks: set default dates before_create
- [ ] Write specs (include status transition tests)

### Model: Invoice
- [ ] Validations (amounts consistent)
- [ ] Associations (belongs_to customer, subscription; has_many line_items)
- [ ] Enum: status (draft, open, paid, void, refunded, partially_refunded)
- [ ] Readonly if finalized?: Override `readonly?` to return true if finalized
- [ ] Method: `finalize!`
- [ ] Method: `mark_paid!`
- [ ] Write specs (test immutability after finalization)

### Model: Ledger::Entry
- [ ] Validations (idempotency_key unique, amounts not zero)
- [ ] Associations (belongs_to entity, polymorphic)
- [ ] Enum: entry_type (charge, payment, refund, credit, adjustment)
- [ ] Override `readonly?` to always return true (append-only)
- [ ] Scopes: for_customer, for_invoice, by_currency
- [ ] Write specs (test immutability via trigger)

### Model Concerns
- [ ] Create `app/models/concerns/identifiable.rb`
  - [ ] Generate external IDs (cus_, sub_, inv_, etc.)
  - [ ] Use SecureRandom or nanoid
  - [ ] Set before_create callback
- [ ] Create `app/models/concerns/monetizable.rb` (optional)
  - [ ] Helper methods for money formatting
  - [ ] Currency conversions

### Model Tests
- [ ] All models have specs in spec/models/
- [ ] Test validations with shoulda-matchers
- [ ] Test associations
- [ ] Test scopes
- [ ] Test custom methods
- [ ] Run: `rspec spec/models` - all passing
- [ ] Check coverage: >85% on models

**Milestone 3**: ✅ All models created, associations working, tests passing

---

## Phase 4: Service Objects (Week 2)

### Ledger Services
- [ ] Create `app/services/ledger/append_entry_service.rb`
  - [ ] Initialize with entity, amount, currency, entry_type, idempotency_key
  - [ ] Handle RecordNotUnique (idempotency)
  - [ ] Return created or existing entry
  - [ ] Write service spec with idempotency tests
- [ ] Create `app/services/ledger/calculate_balance_service.rb`
  - [ ] Initialize with entity, currency, as_of timestamp
  - [ ] Use SQL CASE for signed amounts
  - [ ] Return integer (cents)
  - [ ] Write spec with multiple entry types
- [ ] Create `app/services/ledger/reconciliation_service.rb` (optional)

### Billing Services
- [ ] Create `app/services/billing/subscription_creator_service.rb`
  - [ ] Initialize with customer, price, trial_days, idempotency_key
  - [ ] Create subscription
  - [ ] Schedule trial end job if applicable
  - [ ] Enqueue webhook event
  - [ ] Wrap in transaction
  - [ ] Write spec (happy path + error cases)
- [ ] Create `app/services/billing/subscription_canceller_service.rb`
  - [ ] Support cancel_at_period_end and immediate cancellation
  - [ ] Calculate proration for immediate cancellation
  - [ ] Create refund ledger entries if needed
  - [ ] Update subscription status
  - [ ] Write spec
- [ ] Create `app/services/billing/subscription_upgrader_service.rb`
  - [ ] Calculate proration
  - [ ] Create credit and charge ledger entries
  - [ ] Update subscription to new price
  - [ ] Generate proration invoice
  - [ ] Write spec with proration tests
- [ ] Create `app/services/billing/invoice_generator_service.rb`
  - [ ] Initialize with subscription
  - [ ] Create invoice with status: draft
  - [ ] Add subscription line item
  - [ ] Add usage line items (if metered)
  - [ ] Calculate totals
  - [ ] Write spec
- [ ] Create `app/services/billing/invoice_finalizer_service.rb`
  - [ ] Set finalized_at timestamp
  - [ ] Create ledger entry for charge
  - [ ] Change status to open
  - [ ] Enqueue webhook
  - [ ] Write spec (test immutability after finalization)
- [ ] Create `app/services/billing/proration_calculator_service.rb`
  - [ ] Calculate days remaining / days in period
  - [ ] Return credit amount and new charge amount
  - [ ] Handle edge cases (leap years, month boundaries)
  - [ ] Write property-based tests

### Refund Services
- [ ] Create `app/services/refunds/refund_processor_service.rb`
  - [ ] Validate refund amount <= invoice total
  - [ ] Create refund record
  - [ ] Create ledger entry
  - [ ] Update invoice amounts
  - [ ] Enqueue webhook
  - [ ] Write spec

### Webhook Services
- [ ] Create `app/services/webhooks/signature_verifier_service.rb`
  - [ ] HMAC-SHA256 signature generation
  - [ ] Timestamp freshness check (5-minute window)
  - [ ] Constant-time comparison
  - [ ] Write spec
- [ ] Create `app/services/webhooks/event_dispatcher_service.rb`
  - [ ] Create webhook_event record
  - [ ] Find subscribed endpoints
  - [ ] Enqueue delivery jobs
  - [ ] Write spec
- [ ] Create `app/services/webhooks/delivery_service.rb`
  - [ ] HTTP POST with signature header
  - [ ] 30-second timeout
  - [ ] Log delivery attempt
  - [ ] Return success/failure
  - [ ] Write spec (use VCR for HTTP mocking)

### Usage Services
- [ ] Create `app/services/usage/event_recorder_service.rb`
  - [ ] Validate event_id uniqueness
  - [ ] Validate timestamp within 24 hours
  - [ ] Create usage_event
  - [ ] Write spec
- [ ] Create `app/services/usage/aggregator_service.rb`
  - [ ] Find unprocessed events
  - [ ] Group by subscription + metric
  - [ ] Upsert into summaries table
  - [ ] Mark events as processed
  - [ ] Write spec

### Service Concerns
- [ ] Create `app/services/concerns/idempotent.rb`
  - [ ] with_idempotency method
  - [ ] Redis-backed locking
  - [ ] Cache results for 24 hours
  - [ ] Write spec

### Service Tests
- [ ] All services have specs
- [ ] Test happy paths
- [ ] Test error cases
- [ ] Test idempotency
- [ ] Test transaction rollbacks
- [ ] Run: `rspec spec/services` - all passing
- [ ] Coverage >90% on services

**Milestone 4**: ✅ Business logic in services, thoroughly tested

---

## Phase 5: Background Jobs (Week 3-4)

### Sidekiq Setup
- [ ] Configure Sidekiq in config/application.rb
- [ ] Create config/sidekiq.yml
  - [ ] Define queues (critical, default, low)
  - [ ] Set concurrency
- [ ] Configure Redis connection
- [ ] Create config/initializers/sidekiq.rb
  - [ ] Set up sidekiq-cron jobs
- [ ] Add Sidekiq web UI route (with auth)
- [ ] Test: `bundle exec sidekiq` starts

### Billing Jobs
- [ ] Create `app/jobs/billing/cycle_job.rb`
  - [ ] Run daily at 00:00 UTC
  - [ ] Find subscriptions due for renewal
  - [ ] Enqueue individual renewal jobs
  - [ ] Find trial endings
  - [ ] Find scheduled cancellations
  - [ ] Write spec
- [ ] Create `app/jobs/billing/trial_end_job.rb`
  - [ ] Load subscription
  - [ ] Generate first invoice
  - [ ] Update status to active
  - [ ] Enqueue webhook
  - [ ] Write spec
- [ ] Create `app/jobs/billing/subscription_renewal_job.rb`
  - [ ] Acquire advisory lock
  - [ ] Generate invoice
  - [ ] Create ledger entries
  - [ ] Update next_billing_date
  - [ ] Enqueue webhook
  - [ ] Write spec (test lock prevents duplicates)

### Webhook Jobs
- [ ] Create `app/jobs/webhooks/delivery_job.rb`
  - [ ] Load webhook event and endpoint
  - [ ] Call DeliveryService
  - [ ] Log delivery attempt
  - [ ] Configure retry: 10 attempts, exponential backoff
  - [ ] Handle retries_exhausted (dead letter queue)
  - [ ] Write spec
- [ ] Create `app/jobs/webhooks/processor_job.rb` (for incoming webhooks)
  - [ ] Verify signature
  - [ ] Store event
  - [ ] Process based on event type
  - [ ] Idempotent processing
  - [ ] Write spec

### Usage Jobs
- [ ] Create `app/jobs/usage/aggregation_job.rb`
  - [ ] Run hourly via sidekiq-cron
  - [ ] Call AggregatorService
  - [ ] Process in batches (1000 events)
  - [ ] Write spec

### Refund Jobs
- [ ] Create `app/jobs/refunds/processing_job.rb`
  - [ ] Call RefundProcessorService
  - [ ] Handle failures gracefully
  - [ ] Write spec

### Sidekiq Cron Configuration
- [ ] Configure in config/initializers/sidekiq.rb:
  - [ ] BillingCycleJob: daily at 00:00 UTC
  - [ ] UsageAggregationJob: hourly
- [ ] Test cron jobs can be triggered manually

### Job Tests
- [ ] All jobs have specs
- [ ] Test job enqueueing
- [ ] Test retry logic
- [ ] Test idempotency
- [ ] Run: `rspec spec/jobs` - all passing

**Milestone 5**: ✅ Background processing working, scheduled jobs configured

---

## Phase 6: API Controllers (Week 4)

### Base Controller Setup
- [ ] Create `app/controllers/api/v1/base_controller.rb`
  - [ ] Include Pundit for authorization
  - [ ] before_action :authenticate_api_key!
  - [ ] before_action :set_default_format (json)
  - [ ] Rescue common errors (404, 422, 401, 403, 500)
  - [ ] Helper: current_api_key, current_account
  - [ ] Helper: idempotency_key from headers
- [ ] Create `app/controllers/application_controller.rb`
  - [ ] API-only base

### API Routes
- [ ] Configure config/routes.rb
  - [ ] Namespace :api
  - [ ] Namespace :v1
  - [ ] Resources for customers, subscriptions, invoices, etc.
  - [ ] Custom member actions (cancel, upgrade, balance)
  - [ ] Webhook inbound route
- [ ] Add health check route: GET /health

### Customers Controller
- [ ] Create `app/controllers/api/v1/customers_controller.rb`
  - [ ] index: List customers (paginated)
  - [ ] show: Get customer
  - [ ] create: Create customer (with idempotency)
  - [ ] update: Update customer
  - [ ] balance: Get customer balance
  - [ ] Strong params
- [ ] Write request specs for all endpoints

### Subscriptions Controller
- [ ] Create `app/controllers/api/v1/subscriptions_controller.rb`
  - [ ] index: List subscriptions
  - [ ] show: Get subscription
  - [ ] create: Create subscription (call service)
  - [ ] cancel: Cancel subscription
  - [ ] upgrade: Upgrade subscription
  - [ ] Strong params
- [ ] Write request specs

### Invoices Controller
- [ ] Create `app/controllers/api/v1/invoices_controller.rb`
  - [ ] index: List invoices (with eager loading)
  - [ ] show: Get invoice
  - [ ] pdf: Download invoice as PDF (future)
  - [ ] pay: Mark invoice as paid
- [ ] Write request specs

### Prices Controller
- [ ] Create `app/controllers/api/v1/prices_controller.rb`
  - [ ] index: List prices
  - [ ] show: Get price
- [ ] Write request specs

### Refunds Controller
- [ ] Create `app/controllers/api/v1/refunds_controller.rb`
  - [ ] create: Issue refund
  - [ ] show: Get refund details
- [ ] Write request specs

### Usage Events Controller
- [ ] Create `app/controllers/api/v1/usage_events_controller.rb`
  - [ ] create: Report usage (bulk support)
  - [ ] Return 202 Accepted (async processing)
- [ ] Write request specs

### Webhook Endpoints Controller
- [ ] Create `app/controllers/api/v1/webhook_endpoints_controller.rb`
  - [ ] index, create, show, update, destroy
- [ ] Write request specs

### Reports Controller
- [ ] Create `app/controllers/api/v1/reports_controller.rb`
  - [ ] mrr: Monthly recurring revenue
  - [ ] revenue_recognition: Revenue recognition report
  - [ ] ledger_export: Export ledger as CSV
- [ ] Write request specs

### Webhooks Inbound Controller
- [ ] Create `app/controllers/webhooks/inbound_controller.rb`
  - [ ] create: Receive webhooks from external systems
  - [ ] Verify signature
  - [ ] Store event
  - [ ] Return 202 Accepted
- [ ] Write request specs

### Controller Tests
- [ ] All controllers have request specs
- [ ] Test authentication
- [ ] Test authorization (via Pundit)
- [ ] Test error responses
- [ ] Test pagination
- [ ] Test idempotency
- [ ] Run: `rspec spec/requests` - all passing

**Milestone 6**: ✅ RESTful API working, all endpoints tested

---

## Phase 7: Serializers (Week 4)

### Serializer Setup
- [ ] Decide on serialization approach (custom or ActiveModel::Serializers)
- [ ] Create base serializer if needed

### Core Serializers
- [ ] Create `app/serializers/api/v1/customer_serializer.rb`
  - [ ] Format: id (customer_id), email, name, currency, metadata, created (Unix timestamp)
- [ ] Create `app/serializers/api/v1/subscription_serializer.rb`
  - [ ] Include nested price
  - [ ] Format timestamps as Unix epochs
- [ ] Create `app/serializers/api/v1/invoice_serializer.rb`
  - [ ] Include line_items
  - [ ] Format amounts in cents
- [ ] Create `app/serializers/api/v1/price_serializer.rb`
- [ ] Create `app/serializers/api/v1/refund_serializer.rb`
- [ ] Create `app/serializers/api/v1/usage_event_serializer.rb`
- [ ] Create `app/serializers/api/v1/webhook_endpoint_serializer.rb`
- [ ] Create `app/serializers/api/v1/error_serializer.rb`

### Serializer Tests
- [ ] Test serializer output structure
- [ ] Test nested objects
- [ ] Test timestamp formatting
- [ ] Benchmark serialization performance

**Milestone 7**: ✅ Consistent JSON API responses

---

## Phase 8: Authorization & Security (Week 5)

### API Key Authentication
- [ ] Generate ApiKey model migration (if not done)
- [ ] Implement ApiKey.generate! class method
  - [ ] Generate random key (sk_live_ or sk_test_)
  - [ ] Store bcrypt digest
  - [ ] Return plain text key (only time it's visible)
- [ ] Implement authenticate_api_key! in BaseController
  - [ ] Extract key from Authorization header
  - [ ] Find and verify against digest
  - [ ] Use constant-time comparison
  - [ ] Touch last_used_at
- [ ] Create rake task to generate API keys
- [ ] Write specs for authentication

### Pundit Policies
- [ ] Create `app/policies/application_policy.rb`
- [ ] Create `app/policies/customer_policy.rb`
  - [ ] index?, show?, create?, update?
  - [ ] Scope: filter by account
- [ ] Create `app/policies/subscription_policy.rb`
- [ ] Create `app/policies/invoice_policy.rb`
  - [ ] Prevent update if finalized
- [ ] Create `app/policies/refund_policy.rb`
  - [ ] Only admin/finance can refund
- [ ] Create `app/policies/report_policy.rb`
- [ ] Apply authorize in controllers
- [ ] Write policy specs

### Rate Limiting (Rack::Attack)
- [ ] Create config/initializers/rack_attack.rb
  - [ ] Throttle by IP: 1000 req/min
  - [ ] Throttle by API key: 10,000 req/hour
  - [ ] Block malicious IPs (Redis-backed)
  - [ ] Return 429 with Retry-After header
- [ ] Configure Redis cache store
- [ ] Test rate limiting in specs

### Webhook Security
- [ ] Implement signature generation in WebhookEndpoint
- [ ] Implement signature verification in WebhooksController
- [ ] Test signature mismatch rejection
- [ ] Test timestamp replay attack prevention

### Security Headers
- [ ] Configure HTTPS enforcement (production)
- [ ] Add security headers middleware
  - [ ] X-Frame-Options
  - [ ] X-Content-Type-Options
  - [ ] X-XSS-Protection
- [ ] Configure CORS (if needed)

### Security Tests
- [ ] Test unauthorized access blocked
- [ ] Test invalid API keys rejected
- [ ] Test rate limiting enforced
- [ ] Test webhook signature verification
- [ ] Run security audit: `bundle audit`

**Milestone 8**: ✅ API secured, rate limited, authorized

---

## Phase 9: Testing & Quality (Week 5-6)

### Test Coverage
- [ ] Run: `COVERAGE=true rspec`
- [ ] Check coverage report in coverage/index.html
- [ ] Ensure >90% overall coverage
- [ ] Ensure >95% on services and models
- [ ] Add tests for uncovered lines

### Property-Based Testing
- [ ] Install rspec-propcheck
- [ ] Create spec/property/ directory
- [ ] Create `spec/property/ledger_balance_spec.rb`
  - [ ] Property: balance equals sum of entries
  - [ ] Property: add then subtract = zero
  - [ ] Property: balance is associative
  - [ ] Run 1000+ test cases
- [ ] Create `spec/property/proration_spec.rb`
  - [ ] Property: credit + charge = correct net
  - [ ] Property: proration always <= original amount
- [ ] All property tests passing

### Integration Tests
- [ ] Test complete billing cycle:
  - [ ] Create customer
  - [ ] Create subscription with trial
  - [ ] Trial ends → invoice generated
  - [ ] Invoice finalized → ledger entry created
  - [ ] Webhook delivered
- [ ] Test usage billing flow
- [ ] Test refund flow
- [ ] Test subscription upgrade with proration

### Performance Testing
- [ ] Install bullet gem (N+1 detection)
- [ ] Run app with bullet in development
- [ ] Fix all N+1 queries
- [ ] Benchmark critical endpoints (<200ms p95)
- [ ] Optimize slow queries with EXPLAIN ANALYZE

### Code Quality
- [ ] Install rubocop
- [ ] Configure .rubocop.yml
- [ ] Run: `rubocop` and fix violations
- [ ] Install brakeman (security scanner)
- [ ] Run: `brakeman` and fix issues
- [ ] Code review: Check for fat controllers, fat models

### Factory & Test Data
- [ ] Create FactoryBot factories for all models
- [ ] Use faker for realistic test data
- [ ] Create traits for different scenarios
- [ ] Test factories are valid

**Milestone 9**: ✅ Comprehensive test suite, >90% coverage, no N+1 queries

---

## Phase 10: Monitoring & Logging (Week 6)

### Structured Logging
- [ ] Install lograge gem
- [ ] Configure in config/environments/production.rb
- [ ] Add custom fields (request_id, user_id, api_key_id)
- [ ] Format logs as JSON
- [ ] Test log output

### Request ID Tracking
- [ ] Ensure ActionDispatch::RequestId middleware active
- [ ] Include request_id in all logs
- [ ] Return request_id in error responses
- [ ] Test request_id present in logs

### Error Tracking
- [ ] Set up error tracking (Sentry, Rollbar, or Honeybadger)
- [ ] Install gem
- [ ] Configure initializer
- [ ] Test error reporting
- [ ] Set up alerts for critical errors

### Performance Monitoring
- [ ] Consider APM tool (Scout, New Relic, AppSignal)
- [ ] Track endpoint response times
- [ ] Track background job durations
- [ ] Set up slow query alerts

### Health Checks
- [ ] Create `app/controllers/health_controller.rb`
  - [ ] GET /health returns 200 OK
  - [ ] Check database connection
  - [ ] Check Redis connection
  - [ ] Return JSON with status
- [ ] Test health endpoint

### Metrics & Dashboards
- [ ] Log key business metrics
  - [ ] Subscriptions created/canceled
  - [ ] Invoices generated/paid
  - [ ] MRR changes
- [ ] Create Sidekiq monitoring dashboard
- [ ] Document how to access metrics

**Milestone 10**: ✅ Production-ready logging and monitoring

---

## Phase 11: Documentation (Week 6-7)

### API Documentation
- [ ] Install rswag or similar for OpenAPI/Swagger
- [ ] Document all endpoints:
  - [ ] Request/response formats
  - [ ] Required headers (Authorization, Idempotency-Key)
  - [ ] Example requests and responses
  - [ ] Error codes
- [ ] Generate API docs: `rake rswag:specs:swaggerize`
- [ ] Host docs at /api-docs

### Code Documentation
- [ ] Add YARD comments to complex methods
- [ ] Document service object interfaces
- [ ] Document key design decisions in code comments
- [ ] Generate documentation: `yard doc`

### Project Documentation
- [ ] Update main README.md
  - [ ] Project description
  - [ ] Architecture overview
  - [ ] Setup instructions
  - [ ] Running tests
  - [ ] Deployment guide
- [ ] Create ARCHITECTURE.md (link to prds/)
- [ ] Create CONTRIBUTING.md
- [ ] Create CHANGELOG.md

### Deployment Documentation
- [ ] Document environment variables needed
- [ ] Document database setup for production
- [ ] Document Sidekiq configuration
- [ ] Document backup procedures
- [ ] Document rollback procedures

**Milestone 11**: ✅ Comprehensive documentation for developers and operators

---

## Phase 12: Production Deployment (Week 7-8)

### Pre-Deployment Checklist
- [ ] All tests passing: `rspec`
- [ ] No rubocop violations: `rubocop`
- [ ] No security issues: `brakeman`
- [ ] Database migrations are reversible
- [ ] Secrets not in version control
- [ ] .env.example up to date

### Environment Configuration
- [ ] Create .env.production (don't commit!)
  - [ ] DATABASE_URL
  - [ ] REDIS_URL
  - [ ] SECRET_KEY_BASE (generate with `rails secret`)
  - [ ] RAILS_ENV=production
  - [ ] WEBHOOK_SIGNING_SECRET
  - [ ] API keys for external services
- [ ] Configure production database
- [ ] Configure production Redis

### Database Setup (Production)
- [ ] Create production database
- [ ] Run migrations: `RAILS_ENV=production rails db:migrate`
- [ ] Verify schema loaded correctly
- [ ] Set up database backups (daily)
- [ ] Test database restore procedure

### Docker Production Build
- [ ] Build production image: `docker build -t rails_stripelet:latest .`
- [ ] Test production image locally
- [ ] Push to container registry (Docker Hub, ECR, GCR)
- [ ] Tag with version number

### Deployment Platform Setup
Choose one:

#### Option A: Heroku
- [ ] Create Heroku app: `heroku create rails-stripelet`
- [ ] Add PostgreSQL addon: `heroku addons:create heroku-postgresql`
- [ ] Add Redis addon: `heroku addons:create heroku-redis`
- [ ] Set environment variables: `heroku config:set KEY=VALUE`
- [ ] Deploy: `git push heroku main`
- [ ] Run migrations: `heroku run rails db:migrate`
- [ ] Scale workers: `heroku ps:scale worker=1`

#### Option B: Fly.io
- [ ] Install flyctl
- [ ] Run: `fly launch`
- [ ] Configure fly.toml
- [ ] Add PostgreSQL: `fly postgres create`
- [ ] Add Redis: `fly redis create`
- [ ] Set secrets: `fly secrets set KEY=VALUE`
- [ ] Deploy: `fly deploy`
- [ ] Run migrations: `fly ssh console -C "rails db:migrate"`

#### Option C: Railway
- [ ] Create project on Railway
- [ ] Connect GitHub repo
- [ ] Add PostgreSQL service
- [ ] Add Redis service
- [ ] Configure environment variables
- [ ] Deploy automatically on push

#### Option D: VPS (DigitalOcean, Linode, etc.)
- [ ] Provision server (Ubuntu 22.04 LTS)
- [ ] Install Docker and Docker Compose
- [ ] Copy docker-compose.production.yml to server
- [ ] Set up reverse proxy (Nginx)
- [ ] Configure SSL (Let's Encrypt)
- [ ] Deploy: `docker-compose -f docker-compose.production.yml up -d`
- [ ] Set up automatic backups

### Post-Deployment Verification
- [ ] Test health endpoint: `curl https://your-domain.com/health`
- [ ] Create test customer via API
- [ ] Create test subscription
- [ ] Verify background jobs running
- [ ] Check logs for errors
- [ ] Test webhook delivery
- [ ] Verify Sidekiq dashboard accessible

### SSL & DNS
- [ ] Configure DNS (point domain to deployment)
- [ ] Set up SSL certificate (Let's Encrypt or platform-provided)
- [ ] Enforce HTTPS in production
- [ ] Test: https://your-domain.com

### Monitoring Setup (Production)
- [ ] Configure error tracking (Sentry, etc.)
- [ ] Set up uptime monitoring (UptimeRobot, Pingdom)
- [ ] Configure log aggregation (if using VPS)
- [ ] Set up alerts for:
  - [ ] App errors
  - [ ] Failed background jobs
  - [ ] High response times
  - [ ] Database connection issues

### Backups
- [ ] Configure automated database backups (daily)
- [ ] Test backup restoration
- [ ] Configure Redis persistence (if needed)
- [ ] Document backup retention policy

### CI/CD Pipeline (Optional but Recommended)
- [ ] Create .github/workflows/ci.yml
  - [ ] Run tests on every push
  - [ ] Run linters
  - [ ] Run security scans
- [ ] Create .github/workflows/deploy.yml
  - [ ] Auto-deploy on merge to main
  - [ ] Run migrations
  - [ ] Smoke tests post-deploy

**Milestone 12**: ✅ Application deployed to production and running

---

## Phase 13: Post-Launch (Ongoing)

### Monitoring & Maintenance
- [ ] Monitor error rates daily
- [ ] Monitor response times
- [ ] Monitor Sidekiq queue depths
- [ ] Review logs weekly
- [ ] Update dependencies monthly: `bundle update`

### Performance Optimization
- [ ] Add database read replicas (if needed)
- [ ] Implement caching (Redis) for expensive queries
- [ ] Consider CDN for static assets
- [ ] Optimize database queries based on production data

### Feature Additions
- [ ] PDF invoice generation
- [ ] Email notifications (with Action Mailer)
- [ ] Dunning management (failed payments)
- [ ] Tax calculation integration
- [ ] Multi-tenancy support
- [ ] GraphQL API

### Security Maintenance
- [ ] Run bundle audit weekly
- [ ] Update dependencies for security patches
- [ ] Rotate API secrets quarterly
- [ ] Review access logs for suspicious activity

### Documentation Updates
- [ ] Keep README up to date
- [ ] Document new features
- [ ] Update API documentation
- [ ] Maintain CHANGELOG

**Final Milestone**: ✅ Production application with ongoing maintenance

---

## 🎯 Success Criteria

You've successfully built Rails Stripelet when:

- ✅ All tests passing (>90% coverage)
- ✅ Application deployed to production
- ✅ API fully documented
- ✅ No critical security vulnerabilities
- ✅ Monitoring and alerts configured
- ✅ Background jobs processing reliably
- ✅ Can create subscriptions, generate invoices, process refunds
- ✅ Webhooks delivering with retries
- ✅ Usage billing working end-to-end
- ✅ Database enforces financial correctness via triggers
- ✅ Idempotency working for all financial operations
- ✅ Rate limiting protecting API
- ✅ Clean, maintainable codebase following Rails conventions

---

## 📊 Progress Tracking

**Overall Progress**: ____ / 300+ items completed

**Phase Completion**:
- [ ] Phase 1: Project Foundation
- [ ] Phase 2: Database Schema
- [ ] Phase 3: Models
- [ ] Phase 4: Services
- [ ] Phase 5: Background Jobs
- [ ] Phase 6: Controllers
- [ ] Phase 7: Serializers
- [ ] Phase 8: Security
- [ ] Phase 9: Testing
- [ ] Phase 10: Monitoring
- [ ] Phase 11: Documentation
- [ ] Phase 12: Deployment
- [ ] Phase 13: Post-Launch

---

**Remember**: This is a marathon, not a sprint. Work steadily, test thoroughly, and deploy confidently. You're building a production-grade billing system!

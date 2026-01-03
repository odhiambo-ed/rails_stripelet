# Rails Stripelet - Backend Folder Structure

## Overview
This document outlines the Rails API backend folder structure demonstrating senior-level organization principles: separation of concerns, service-oriented architecture, clear boundaries, and maintainability.

---

## Complete Folder Structure

```
rails_stripelet/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── base_controller.rb
│   │   │       ├── customers_controller.rb
│   │   │       ├── subscriptions_controller.rb
│   │   │       ├── invoices_controller.rb
│   │   │       ├── prices_controller.rb
│   │   │       ├── refunds_controller.rb
│   │   │       ├── usage_events_controller.rb
│   │   │       ├── webhook_endpoints_controller.rb
│   │   │       └── reports_controller.rb
│   │   ├── webhooks/
│   │   │   └── inbound_controller.rb
│   │   └── application_controller.rb
│   │
│   ├── models/
│   │   ├── concerns/
│   │   │   ├── identifiable.rb
│   │   │   └── monetizable.rb
│   │   ├── customer.rb
│   │   ├── subscription.rb
│   │   ├── invoice.rb
│   │   ├── invoice_line_item.rb
│   │   ├── price.rb
│   │   ├── product.rb
│   │   ├── refund.rb
│   │   ├── usage_event.rb
│   │   ├── subscription_usage_summary.rb
│   │   ├── webhook_endpoint.rb
│   │   ├── webhook_event.rb
│   │   ├── webhook_delivery_attempt.rb
│   │   ├── ledger/
│   │   │   └── entry.rb
│   │   ├── api_key.rb
│   │   └── audit_event.rb
│   │
│   ├── services/
│   │   ├── concerns/
│   │   │   └── idempotent.rb
│   │   ├── ledger/
│   │   │   ├── append_entry_service.rb
│   │   │   ├── calculate_balance_service.rb
│   │   │   └── reconciliation_service.rb
│   │   ├── billing/
│   │   │   ├── subscription_creator_service.rb
│   │   │   ├── subscription_canceller_service.rb
│   │   │   ├── subscription_upgrader_service.rb
│   │   │   ├── invoice_generator_service.rb
│   │   │   ├── invoice_finalizer_service.rb
│   │   │   └── proration_calculator_service.rb
│   │   ├── webhooks/
│   │   │   ├── signature_verifier_service.rb
│   │   │   ├── event_dispatcher_service.rb
│   │   │   └── delivery_service.rb
│   │   ├── refunds/
│   │   │   └── refund_processor_service.rb
│   │   ├── usage/
│   │   │   ├── event_recorder_service.rb
│   │   │   └── aggregator_service.rb
│   │   └── reports/
│   │       ├── mrr_calculator_service.rb
│   │       └── revenue_recognition_service.rb
│   │
│   ├── jobs/
│   │   ├── application_job.rb
│   │   ├── billing/
│   │   │   ├── cycle_job.rb
│   │   │   ├── trial_end_job.rb
│   │   │   └── subscription_renewal_job.rb
│   │   ├── webhooks/
│   │   │   ├── delivery_job.rb
│   │   │   └── processor_job.rb
│   │   ├── usage/
│   │   │   └── aggregation_job.rb
│   │   └── refunds/
│   │       └── processing_job.rb
│   │
│   ├── policies/
│   │   ├── application_policy.rb
│   │   ├── customer_policy.rb
│   │   ├── subscription_policy.rb
│   │   ├── invoice_policy.rb
│   │   ├── refund_policy.rb
│   │   └── report_policy.rb
│   │
│   ├── serializers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── customer_serializer.rb
│   │   │       ├── subscription_serializer.rb
│   │   │       ├── invoice_serializer.rb
│   │   │       ├── refund_serializer.rb
│   │   │       ├── usage_event_serializer.rb
│   │   │       ├── webhook_endpoint_serializer.rb
│   │   │       └── error_serializer.rb
│   │
│   ├── validators/
│   │   ├── currency_validator.rb
│   │   ├── idempotency_key_validator.rb
│   │   ├── amount_validator.rb
│   │   └── webhook_url_validator.rb
│   │
│   └── lib/
│       └── stripe_id_generator.rb
│
├── config/
│   ├── application.rb
│   ├── routes.rb
│   ├── database.yml
│   ├── cable.yml
│   ├── credentials.yml.enc
│   ├── environments/
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   ├── initializers/
│   │   ├── cors.rb
│   │   ├── sidekiq.rb
│   │   ├── redis.rb
│   │   ├── inflections.rb
│   │   ├── rate_limit.rb
│   │   └── money.rb
│   └── locales/
│       └── en.yml
│
├── db/
│   ├── migrate/
│   │   ├── 20260101000001_create_customers.rb
│   │   ├── 20260101000002_create_products.rb
│   │   ├── 20260101000003_create_prices.rb
│   │   ├── 20260101000004_create_subscriptions.rb
│   │   ├── 20260101000005_create_invoices.rb
│   │   ├── 20260101000006_create_invoice_line_items.rb
│   │   ├── 20260101000007_create_ledger_entries.rb
│   │   ├── 20260101000008_create_usage_events.rb
│   │   ├── 20260101000009_create_subscription_usage_summaries.rb
│   │   ├── 20260101000010_create_refunds.rb
│   │   ├── 20260101000011_create_webhook_endpoints.rb
│   │   ├── 20260101000012_create_webhook_events.rb
│   │   ├── 20260101000013_create_webhook_delivery_attempts.rb
│   │   ├── 20260101000014_create_api_keys.rb
│   │   ├── 20260101000015_create_audit_events.rb
│   │   └── 20260101000016_add_indexes_for_performance.rb
│   ├── seeds.rb
│   └── schema.rb
│
├── spec/
│   ├── factories/
│   │   ├── customers.rb
│   │   ├── subscriptions.rb
│   │   ├── invoices.rb
│   │   ├── prices.rb
│   │   ├── ledger_entries.rb
│   │   ├── usage_events.rb
│   │   └── webhook_endpoints.rb
│   ├── models/
│   │   ├── customer_spec.rb
│   │   ├── subscription_spec.rb
│   │   ├── invoice_spec.rb
│   │   ├── ledger/
│   │   │   └── entry_spec.rb
│   │   └── webhook_event_spec.rb
│   ├── services/
│   │   ├── ledger/
│   │   │   ├── append_entry_service_spec.rb
│   │   │   └── calculate_balance_service_spec.rb
│   │   ├── billing/
│   │   │   ├── subscription_creator_service_spec.rb
│   │   │   ├── invoice_generator_service_spec.rb
│   │   │   └── proration_calculator_service_spec.rb
│   │   └── webhooks/
│   │       └── signature_verifier_service_spec.rb
│   ├── requests/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── customers_spec.rb
│   │   │       ├── subscriptions_spec.rb
│   │   │       ├── invoices_spec.rb
│   │   │       └── refunds_spec.rb
│   │   └── webhooks/
│   │       └── inbound_spec.rb
│   ├── jobs/
│   │   ├── billing/
│   │   │   └── cycle_job_spec.rb
│   │   └── webhooks/
│   │       └── delivery_job_spec.rb
│   ├── policies/
│   │   └── customer_policy_spec.rb
│   ├── property/
│   │   ├── ledger_balance_spec.rb
│   │   └── proration_spec.rb
│   ├── support/
│   │   ├── api_helpers.rb
│   │   ├── auth_helpers.rb
│   │   └── factory_bot.rb
│   └── rails_helper.rb
│
├── lib/
│   └── tasks/
│       ├── billing.rake
│       ├── reports.rake
│       └── webhooks.rake
│
├── docker-compose.yml
├── Dockerfile
├── .dockerignore
├── Gemfile
├── Gemfile.lock
├── config.ru
├── Rakefile
├── README.md
└── .env.example
```

---

## Key Architectural Decisions

### 1. Services Isolate Business Logic

**Why Services?**
- Controllers remain thin (validation, params, response only)
- Business logic is testable in isolation
- Reusable across controllers, jobs, and console
- Clear boundaries and single responsibility

**Service Pattern Example:**

```ruby
# app/services/billing/subscription_creator_service.rb
module Billing
  class SubscriptionCreatorService
    include Idempotent
    
    def initialize(customer:, price:, idempotency_key:, **options)
      @customer = customer
      @price = price
      @idempotency_key = idempotency_key
      @trial_days = options[:trial_days] || 0
      @metadata = options[:metadata] || {}
    end
    
    def call
      with_idempotency(@idempotency_key) do
        ActiveRecord::Base.transaction do
          create_subscription
          schedule_trial_end_job if trialing?
          enqueue_webhook_event
          subscription
        end
      end
    end
    
    private
    
    attr_reader :customer, :price, :idempotency_key, :trial_days, :metadata, :subscription
    
    def create_subscription
      @subscription = Subscription.create!(
        customer: customer,
        price: price,
        status: initial_status,
        trial_end_at: trial_end_date,
        next_billing_date: first_billing_date,
        metadata: metadata
      )
    end
    
    def initial_status
      trial_days > 0 ? :trialing : :active
    end
    
    def trialing?
      subscription.trialing?
    end
    
    # ... rest of implementation
  end
end
```

**Usage in Controller:**
```ruby
# app/controllers/api/v1/subscriptions_controller.rb
module Api
  module V1
    class SubscriptionsController < BaseController
      def create
        service = Billing::SubscriptionCreatorService.new(
          customer: current_customer,
          price: price,
          idempotency_key: request.headers['Idempotency-Key'],
          trial_days: params[:trial_days],
          metadata: params[:metadata]
        )
        
        subscription = service.call
        
        render json: SubscriptionSerializer.new(subscription), status: :created
      rescue Billing::SubscriptionCreatorService::Error => e
        render json: ErrorSerializer.new(e), status: :unprocessable_entity
      end
    end
  end
end
```

---

### 2. Ledger Separated from Billing Logic

**Ledger as Independent Layer:**

```ruby
# app/models/ledger/entry.rb
module Ledger
  class Entry < ApplicationRecord
    self.table_name = 'ledger_entries'
    
    # Immutable - no updates or deletes
    def readonly?
      persisted?
    end
    
    belongs_to :entity, polymorphic: true
    
    enum entry_type: {
      charge: 'charge',
      payment: 'payment',
      refund: 'refund',
      credit: 'credit',
      adjustment: 'adjustment'
    }
    
    validates :idempotency_key, presence: true, uniqueness: true
    validates :amount_cents, presence: true
    validates :currency, presence: true
    validates :entry_type, presence: true
    
    # No balance column - always calculated
  end
end

# app/services/ledger/append_entry_service.rb
module Ledger
  class AppendEntryService
    def initialize(entity:, amount_cents:, currency:, entry_type:, idempotency_key:, metadata: {})
      @entity = entity
      @amount_cents = amount_cents
      @currency = currency
      @entry_type = entry_type
      @idempotency_key = idempotency_key
      @metadata = metadata
    end
    
    def call
      Entry.create!(
        entity: entity,
        amount_cents: amount_cents,
        currency: currency,
        entry_type: entry_type,
        idempotency_key: idempotency_key,
        metadata: metadata,
        created_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique
      # Idempotency - already processed
      Entry.find_by!(idempotency_key: idempotency_key)
    end
    
    private
    
    attr_reader :entity, :amount_cents, :currency, :entry_type, :idempotency_key, :metadata
  end
end

# app/services/ledger/calculate_balance_service.rb
module Ledger
  class CalculateBalanceService
    def initialize(entity:, currency: nil, as_of: nil)
      @entity = entity
      @currency = currency
      @as_of = as_of || Time.current
    end
    
    def call
      scope = Entry.where(entity: entity)
      scope = scope.where(currency: currency) if currency
      scope = scope.where('created_at <= ?', as_of)
      
      scope.sum(balance_calculation_sql)
    end
    
    private
    
    attr_reader :entity, :currency, :as_of
    
    def balance_calculation_sql
      <<~SQL
        CASE 
          WHEN entry_type IN ('charge', 'adjustment') THEN amount_cents
          WHEN entry_type IN ('payment', 'refund', 'credit') THEN -amount_cents
          ELSE 0
        END
      SQL
    end
  end
end
```

**Why Separate Ledger?**
- Financial data integrity isolated from business logic
- Append-only ensures immutability
- Can rebuild entire system state from ledger
- Easy to audit and reconcile
- Services interact with ledger only through well-defined interface

---

### 3. Policies for Authorization

**Pundit Policy Example:**

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end
end

# app/policies/invoice_policy.rb
class InvoicePolicy < ApplicationPolicy
  def show?
    user.admin? || invoice_belongs_to_user?
  end
  
  def create?
    user.admin? || user.finance?
  end
  
  def update?
    false # Invoices are immutable
  end
  
  def refund?
    user.admin? || user.finance?
  end
  
  private
  
  def invoice_belongs_to_user?
    record.customer.account_id == user.account_id
  end
end

# app/controllers/api/v1/invoices_controller.rb
module Api
  module V1
    class InvoicesController < BaseController
      def show
        invoice = Invoice.find(params[:id])
        authorize invoice # Calls InvoicePolicy#show?
        
        render json: InvoiceSerializer.new(invoice)
      end
      
      def refund
        invoice = Invoice.find(params[:id])
        authorize invoice, :refund? # Calls InvoicePolicy#refund?
        
        # ... refund logic
      end
    end
  end
end
```

**Authorization Levels:**
- **Admin**: Full access
- **Finance**: View reports, issue refunds, view all invoices
- **Support**: View customer data, cannot modify billing
- **API Key**: Scoped to specific account, enforced at controller level

---

### 4. API Versioning

**Routes Structure:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :customers, only: [:index, :show, :create, :update] do
        member do
          get :balance
          post :credits
        end
      end
      
      resources :subscriptions, only: [:index, :show, :create] do
        member do
          post :cancel
          post :upgrade
        end
      end
      
      resources :invoices, only: [:index, :show] do
        member do
          get :pdf
          post :pay
        end
      end
      
      resources :refunds, only: [:create, :show]
      resources :usage_events, only: [:create]
      resources :webhook_endpoints, only: [:index, :create, :show, :update, :destroy]
      
      namespace :reports do
        get :mrr
        get :revenue_recognition
        get 'ledger.csv', to: 'ledger#export'
      end
    end
    
    # Future: namespace :v2 do ... end
  end
  
  namespace :webhooks do
    post :inbound, to: 'inbound#create'
  end
  
  # Health check
  get '/health', to: 'health#show'
end
```

**Base Controller with Versioning:**

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      
      before_action :authenticate_api_key!
      before_action :set_default_format
      
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from Pundit::NotAuthorizedError, with: :forbidden
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      
      private
      
      def authenticate_api_key!
        api_key = request.headers['Authorization']&.sub(/^Bearer /, '')
        @current_api_key = ApiKey.active.find_by(key: api_key)
        
        render json: { error: 'Invalid API key' }, status: :unauthorized unless @current_api_key
      end
      
      def current_account
        @current_api_key.account
      end
      
      def set_default_format
        request.format = :json
      end
      
      def not_found
        render json: { error: 'Resource not found' }, status: :not_found
      end
      
      def forbidden
        render json: { error: 'Forbidden' }, status: :forbidden
      end
      
      def unprocessable_entity(exception)
        render json: { 
          error: 'Validation failed', 
          details: exception.record.errors.full_messages 
        }, status: :unprocessable_entity
      end
    end
  end
end
```

**Why API Versioning?**
- Breaking changes don't affect existing integrations
- Gradual migration path for customers
- Can sunset old versions with notice
- Clear communication of API evolution

---

## Service Organization Patterns

### Idempotent Concern

```ruby
# app/services/concerns/idempotent.rb
module Idempotent
  extend ActiveSupport::Concern
  
  class DuplicateOperationError < StandardError; end
  
  included do
    class_attribute :idempotency_store
    self.idempotency_store = Redis.new
  end
  
  def with_idempotency(key, ttl: 24.hours)
    # Check if already processed
    if existing_result = fetch_idempotent_result(key)
      return existing_result
    end
    
    # Acquire lock
    lock_acquired = idempotency_store.set("lock:#{key}", "1", nx: true, ex: 60)
    raise DuplicateOperationError, "Operation in progress" unless lock_acquired
    
    begin
      result = yield
      store_idempotent_result(key, result, ttl)
      result
    ensure
      idempotency_store.del("lock:#{key}")
    end
  end
  
  private
  
  def fetch_idempotent_result(key)
    cached = idempotency_store.get("result:#{key}")
    JSON.parse(cached) if cached
  rescue JSON::ParserError
    nil
  end
  
  def store_idempotent_result(key, result, ttl)
    idempotency_store.setex("result:#{key}", ttl, result.to_json)
  end
end
```

---

## Job Organization

### Billing Cycle Job

```ruby
# app/jobs/billing/cycle_job.rb
module Billing
  class CycleJob < ApplicationJob
    queue_as :critical
    
    # Run daily at 00:00 UTC via sidekiq-cron
    def perform
      process_trial_endings
      process_renewals
      process_cancellations
    end
    
    private
    
    def process_trial_endings
      Subscription.trialing.where('trial_end_at <= ?', Time.current).find_each do |subscription|
        TrialEndJob.perform_async(subscription.id)
      end
    end
    
    def process_renewals
      Subscription.active.where('next_billing_date <= ?', Date.current).find_each do |subscription|
        SubscriptionRenewalJob.perform_async(subscription.id)
      end
    end
    
    def process_cancellations
      Subscription.active.where('cancel_at <= ?', Time.current).find_each do |subscription|
        subscription.update!(status: :canceled)
        Webhooks::DeliveryJob.perform_async('subscription.canceled', subscription.id)
      end
    end
  end
end

# config/initializers/sidekiq.rb
require 'sidekiq/cron'

Sidekiq::Cron::Job.create(
  name: 'Billing Cycle - daily',
  cron: '0 0 * * *', # Daily at midnight UTC
  class: 'Billing::CycleJob'
)

Sidekiq::Cron::Job.create(
  name: 'Usage Aggregation - hourly',
  cron: '0 * * * *', # Every hour
  class: 'Usage::AggregationJob'
)
```

---

## Validators

```ruby
# app/validators/currency_validator.rb
class CurrencyValidator < ActiveModel::EachValidator
  SUPPORTED_CURRENCIES = %w[usd eur gbp cad aud jpy].freeze
  
  def validate_each(record, attribute, value)
    unless SUPPORTED_CURRENCIES.include?(value.to_s.downcase)
      record.errors.add(attribute, "#{value} is not a supported currency")
    end
  end
end

# Usage in model:
# validates :currency, currency: true

# app/validators/idempotency_key_validator.rb
class IdempotencyKeyValidator < ActiveModel::EachValidator
  FORMAT = /\A[a-zA-Z0-9_-]{1,255}\z/
  
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "can't be blank")
    elsif value !~ FORMAT
      record.errors.add(attribute, "invalid format (must be alphanumeric, underscore, or hyphen)")
    end
  end
end
```

---

## Testing Structure

### Property-Based Testing for Financial Logic

```ruby
# spec/property/ledger_balance_spec.rb
require 'rails_helper'
require 'rspec/propcheck'

RSpec.describe 'Ledger Balance Properties' do
  include RSpec::Propcheck
  
  property 'balance always equals sum of entries' do
    forall(entries: array(ledger_entry_generator)) do |entries|
      customer = create(:customer)
      
      entries.each do |entry_params|
        Ledger::AppendEntryService.new(
          entity: customer,
          **entry_params
        ).call
      end
      
      calculated = Ledger::CalculateBalanceService.new(entity: customer).call
      expected = entries.sum { |e| signed_amount(e) }
      
      expect(calculated).to eq(expected)
    end
  end
  
  property 'adding then removing same amount results in zero' do
    forall(amount: integer(min: 1, max: 1_000_000)) do |amount|
      customer = create(:customer)
      
      Ledger::AppendEntryService.new(
        entity: customer,
        amount_cents: amount,
        currency: 'usd',
        entry_type: 'charge',
        idempotency_key: "charge_#{SecureRandom.hex}"
      ).call
      
      Ledger::AppendEntryService.new(
        entity: customer,
        amount_cents: amount,
        currency: 'usd',
        entry_type: 'payment',
        idempotency_key: "payment_#{SecureRandom.hex}"
      ).call
      
      balance = Ledger::CalculateBalanceService.new(entity: customer).call
      expect(balance).to eq(0)
    end
  end
  
  private
  
  def ledger_entry_generator
    hash(
      amount_cents: integer(min: 1, max: 100_000),
      currency: constant('usd'),
      entry_type: one_of('charge', 'payment', 'refund'),
      idempotency_key: lambda { "key_#{SecureRandom.hex}" }
    )
  end
  
  def signed_amount(entry)
    multiplier = %w[charge adjustment].include?(entry[:entry_type]) ? 1 : -1
    entry[:amount_cents] * multiplier
  end
end
```

---

## Environment Configuration

### Development Environment

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  
  # Caching
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
  
  # Background jobs
  config.active_job.queue_adapter = :sidekiq
  
  # Logging
  config.log_level = :debug
  config.log_tags = [:request_id]
end
```

### Production Environment

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  
  # SSL
  config.force_ssl = true
  
  # Caching
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    pool_size: ENV.fetch('RAILS_MAX_THREADS', 5).to_i,
    pool_timeout: 5
  }
  
  # Background jobs
  config.active_job.queue_adapter = :sidekiq
  
  # Logging
  config.log_level = :info
  config.log_tags = [:request_id, :remote_ip]
  config.logger = ActiveSupport::Logger.new(STDOUT)
  
  # Error tracking (add Sentry, Rollbar, etc.)
  # config.middleware.use ExceptionNotification::Rack
end
```

---

## Key Takeaways

### Services Isolate Business Logic
✅ Controllers are thin (params, auth, response)  
✅ Services are testable in isolation  
✅ Reusable across controllers and jobs  
✅ Clear single responsibility  

### Ledger Separated from Billing Logic
✅ Append-only financial records  
✅ Balance always calculated, never stored  
✅ Idempotent operations  
✅ Complete audit trail  

### Policies for Authorization
✅ Pundit policies enforce access control  
✅ Role-based permissions  
✅ API keys scoped to accounts  
✅ Testable authorization logic  

### API Versioning
✅ `/api/v1/` namespace  
✅ Breaking changes in v2  
✅ Gradual migration path  
✅ Clear deprecation strategy  

---

## Next: Implementation

See `database-schema.md` for complete schema and `README.md` for setup instructions.

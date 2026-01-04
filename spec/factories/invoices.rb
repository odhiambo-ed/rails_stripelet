FactoryBot.define do
  factory :invoice do
    customer { association :customer }
    subscription { association :subscription, customer: customer }
    status { 'draft' }
    currency { 'usd' }
    subtotal_cents { 10000 }
    tax_cents { 1000 }
    total_cents { 11000 }
    amount_paid_cents { 0 }
    amount_refunded_cents { 0 }
    amount_due_cents { 11000 }
    period_start { Date.current }
    period_end { 30.days.from_now.to_date }
    due_date { 15.days.from_now.to_date }
    finalized_at { nil }
    paid_at { nil }
    voided_at { nil }
    metadata { {} }
    deleted_at { nil }

    trait :open do
      status { 'open' }
      finalized_at { Time.current }
    end

    trait :paid do
      status { 'paid' }
      finalized_at { Time.current }
      paid_at { Time.current }
      amount_paid_cents { 11000 }
      amount_due_cents { 0 }
    end

    trait :partially_refunded do
      status { 'partially_refunded' }
      finalized_at { Time.current }
      paid_at { Time.current }
      amount_paid_cents { 11000 }
      amount_refunded_cents { 5500 }
      amount_due_cents { 5500 }
    end

    trait :refunded do
      status { 'refunded' }
      finalized_at { Time.current }
      paid_at { Time.current }
      amount_paid_cents { 11000 }
      amount_refunded_cents { 11000 }
      amount_due_cents { 0 }
    end

    trait :void do
      status { 'void' }
      voided_at { Time.current }
    end

    trait :overdue do
      status { 'open' }
      finalized_at { Time.current }
      due_date { 5.days.ago.to_date }
    end
  end
end

FactoryBot.define do
  factory :subscription do
    customer { association :customer }
    price { association :price }
    status { 'trialing' }
    current_period_start { Date.current }
    current_period_end { 30.days.from_now.to_date }
    trial_start_at { Time.current }
    trial_end_at { 14.days.from_now }
    cancel_at { nil }
    canceled_at { nil }
    next_billing_date { 14.days.from_now.to_date }
    metadata { {} }
    deleted_at { nil }

    trait :active do
      status { 'active' }
      trial_start_at { nil }
      trial_end_at { nil }
    end

    trait :with_trial do
      status { 'trialing' }
      trial_start_at { Time.current }
      trial_end_at { 14.days.from_now }
    end

    trait :canceled do
      status { 'canceled' }
      canceled_at { Time.current }
    end

    trait :past_due do
      status { 'past_due' }
      next_billing_date { 5.days.ago.to_date }
    end
  end
end

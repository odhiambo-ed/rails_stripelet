FactoryBot.define do
  factory :price do
    product { association :product }
    currency { 'usd' }
    amount_cents { Faker::Number.between(from: 100, to: 99900) }
    billing_scheme { 'per_unit' }
    interval { 'month' }
    interval_count { 1 }
    active { true }
    metadata { {} }
    deleted_at { nil }
  end
end

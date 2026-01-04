FactoryBot.define do
  factory :subscription_usage_summary do
    association :subscription
    metric { [ 'api_calls', 'storage_gb', 'bandwidth_gb' ].sample }
    period_start { Date.current }
    period_end { 30.days.from_now.to_date }
    total_quantity { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    last_aggregated_at { Time.current }
    metadata { {} }

    trait :api_calls do
      metric { 'api_calls' }
      total_quantity { Faker::Number.between(from: 1000, to: 10000) }
    end

    trait :storage do
      metric { 'storage_gb' }
      total_quantity { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end
  end
end

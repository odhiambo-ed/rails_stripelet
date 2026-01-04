FactoryBot.define do
  factory :usage_event do
    association :subscription
    event_id { "evt_#{SecureRandom.hex(16)}" }
    metric_name { [ 'api_calls', 'storage_gb', 'bandwidth_gb' ].sample }
    quantity { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    timestamp { Faker::Time.between(from: 23.hours.ago, to: Time.current) }
    processed_at { nil }
    metadata { {} }

    trait :processed do
      processed_at { Time.current }
    end

    trait :api_calls do
      metric_name { 'api_calls' }
      quantity { Faker::Number.between(from: 1, to: 1000) }
    end

    trait :storage do
      metric_name { 'storage_gb' }
      quantity { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end
  end
end

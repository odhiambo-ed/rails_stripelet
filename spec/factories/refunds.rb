FactoryBot.define do
  factory :refund do
    association :invoice
    amount_cents { Faker::Number.between(from: 100, to: 5000) }
    currency { 'usd' }
    status { 'pending' }
    reason { [ 'requested_by_customer', 'duplicate', 'fraudulent' ].sample }
    metadata { {} }

    trait :succeeded do
      status { 'succeeded' }
    end

    trait :failed do
      status { 'failed' }
    end

    trait :canceled do
      status { 'canceled' }
    end
  end
end

FactoryBot.define do
  factory :webhook_event do
    event_type { [ 'invoice.paid', 'subscription.created', 'customer.updated' ].sample }
    payload { { data: { id: Faker::Alphanumeric.alphanumeric(number: 10) } } }
    delivered { false }
    attempts_count { 0 }
    metadata { {} }

    trait :delivered do
      delivered { true }
      attempts_count { 1 }
    end

    trait :with_retries do
      attempts_count { 3 }
    end
  end
end

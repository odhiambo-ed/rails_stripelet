FactoryBot.define do
  factory :webhook_endpoint do
    endpoint_id { "MyString" }
    url { "https://#{Faker::Internet.domain_name}/webhooks" }
    secret_digest { BCrypt::Password.create('webhook_secret') }
    events { [ 'invoice.paid', 'subscription.created', 'customer.updated' ] }
    active { true }
    metadata { {} }
    deleted_at { nil }

    trait :inactive do
      active { false }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end

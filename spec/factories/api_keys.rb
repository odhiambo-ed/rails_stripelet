FactoryBot.define do
  factory :api_key do
    name { Faker::App.name }
    key_digest { BCrypt::Password.create('secret_key_123') }
    role { 'standard' }
    last_used_at { nil }
    expires_at { nil }
    revoked_at { nil }
    metadata { {} }

    trait :admin do
      role { 'admin' }
    end

    trait :finance do
      role { 'finance' }
    end

    trait :read_only do
      role { 'read_only' }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { Time.current }
    end
  end
end

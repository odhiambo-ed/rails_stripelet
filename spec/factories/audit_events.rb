FactoryBot.define do
  factory :audit_event do
    association :actor, factory: :api_key
    association :subject, factory: :customer
    action { 'create' }
    change_data { { before: {}, after: { name: 'Test Customer' } } }
    ip_address { Faker::Internet.ip_v4_address }
    metadata { {} }

    trait :update_action do
      action { 'update' }
      change_data { { before: { name: 'Old Name' }, after: { name: 'New Name' } } }
    end

    trait :delete_action do
      action { 'delete' }
    end

    trait :view_action do
      action { 'view' }
    end
  end
end

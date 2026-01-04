FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    active { true }
    metadata { {} }
    deleted_at { nil }
  end
end

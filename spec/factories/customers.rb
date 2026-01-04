FactoryBot.define do
  factory :customer do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    currency { 'usd' }
    metadata { {} }
    deleted_at { nil }
  end
end

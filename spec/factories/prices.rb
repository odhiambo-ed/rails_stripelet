FactoryBot.define do
  factory :price do
    price_id { "MyString" }
    product { nil }
    currency { "MyString" }
    amount_cents { "" }
    billing_scheme { "MyString" }
    interval { "MyString" }
    interval_count { 1 }
    active { false }
    metadata { "" }
  end
end

FactoryBot.define do
  factory :product do
    product_id { "MyString" }
    name { "MyString" }
    description { "MyText" }
    active { false }
    metadata { "" }
  end
end

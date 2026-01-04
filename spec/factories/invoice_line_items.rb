FactoryBot.define do
  factory :invoice_line_item do
    invoice { association :invoice }
    description { Faker::Commerce.product_name }
    quantity { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    unit_amount_cents { Faker::Number.between(from: 100, to: 10000) }
    amount_cents { |li| (li.unit_amount_cents * li.quantity).to_i }
    currency { 'usd' }
    period_start { Date.current }
    period_end { 30.days.from_now.to_date }
    metadata { {} }

    trait :subscription_charge do
      description { 'Pro Plan Monthly' }
      quantity { 1 }
      unit_amount_cents { 9900 }
      amount_cents { 9900 }
    end

    trait :usage_charge do
      description { 'API Usage' }
      quantity { Faker::Number.between(from: 100, to: 10000) }
      unit_amount_cents { 10 }
      amount_cents { |li| (li.unit_amount_cents * li.quantity).to_i }
    end

    trait :with_eur do
      currency { 'eur' }
    end

    trait :with_gbp do
      currency { 'gbp' }
    end
  end
end

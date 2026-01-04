FactoryBot.define do
  factory :invoice_line_item do
    invoice { nil }
    description { "MyText" }
    quantity { "9.99" }
    unit_amount_cents { "" }
    amount_cents { "" }
    currency { "MyString" }
    period_start { "2026-01-05" }
    period_end { "2026-01-05" }
    metadata { "" }
  end
end

FactoryBot.define do
  factory :invoice do
    invoice_id { "MyString" }
    customer { nil }
    subscription { nil }
    status { "MyString" }
    currency { "MyString" }
    subtotal_cents { "" }
    tax_cents { "" }
    total_cents { "" }
    amount_paid_cents { "" }
    amount_refunded_cents { "" }
    amount_due_cents { "" }
    period_start { "2026-01-05" }
    period_end { "2026-01-05" }
    due_date { "2026-01-05" }
    finalized_at { "2026-01-05 00:21:13" }
    paid_at { "2026-01-05 00:21:13" }
    voided_at { "2026-01-05 00:21:13" }
    metadata { "" }
  end
end

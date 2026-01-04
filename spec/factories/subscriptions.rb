FactoryBot.define do
  factory :subscription do
    subscription_id { "MyString" }
    customer { nil }
    price { nil }
    status { "MyString" }
    current_period_start { "2026-01-05" }
    current_period_end { "2026-01-05" }
    trial_start_at { "2026-01-05 00:10:36" }
    trial_end_at { "2026-01-05 00:10:36" }
    cancel_at { "2026-01-05 00:10:36" }
    canceled_at { "2026-01-05 00:10:36" }
    next_billing_date { "2026-01-05" }
    metadata { "" }
  end
end

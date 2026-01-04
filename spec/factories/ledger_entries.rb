FactoryBot.define do
  factory :ledger_entry, class: 'Ledger::Entry' do
    association :entity, factory: :customer
    entry_type { 'credit' }
    amount_cents { Faker::Number.between(from: 100, to: 10000) }
    currency { 'usd' }
    idempotency_key { "idem_#{SecureRandom.hex(16)}" }
    metadata { {} }

    trait :credit do
      entry_type { 'credit' }
      amount_cents { Faker::Number.between(from: 100, to: 10000) }
    end

    trait :debit do
      entry_type { 'debit' }
      amount_cents { -Faker::Number.between(from: 100, to: 10000) }
    end

    trait :refund do
      entry_type { 'refund' }
    end

    trait :with_invoice do
      association :entity, factory: :invoice
    end
  end
end

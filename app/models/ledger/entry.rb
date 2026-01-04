module Ledger
  class Entry < ApplicationRecord
    self.table_name = "ledger_entries"

    belongs_to :entity, polymorphic: true

    enum :entry_type, { charge: "charge", payment: "payment", refund: "refund", credit: "credit", adjustment: "adjustment" }

    validates :idempotency_key, uniqueness: true
    validates :amount_cents, presence: true
    validates :currency, presence: true
  end
end

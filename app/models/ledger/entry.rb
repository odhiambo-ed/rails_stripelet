module Ledger
  class Entry < ApplicationRecord
    self.table_name = "ledger_entries"

    # Enums for entry type and currency
    enum :entry_type, {
      credit: "credit",
      debit: "debit",
      refund: "refund",
      adjustment: "adjustment",
      fee: "fee"
    }, prefix: true

    enum :currency, {
      usd: "usd",
      eur: "eur",
      gbp: "gbp",
      jpy: "jpy"
    }, prefix: true

    # Polymorphic association - can belong to Customer, Invoice, etc.
    belongs_to :entity, polymorphic: true

    # Validations
    validates :idempotency_key, presence: true, uniqueness: true
    validates :amount_cents, presence: true
    validates :currency, presence: true
    validates :entry_type, presence: true
    validates :entity_type, presence: true
    validates :entity_id, presence: true

    # Scopes for querying
    scope :for_entity, ->(entity) { where(entity: entity) }
    scope :by_currency, ->(currency) { where(currency: currency) }
    scope :credits, -> { where(entry_type: "credit") }
    scope :debits, -> { where(entry_type: "debit") }
    scope :before, ->(timestamp) { where("created_at <= ?", timestamp) }

    # Make entries immutable - prevent updates and deletes
    before_update :prevent_update
    before_destroy :prevent_destroy

    private

    # Prevent any updates to ledger entries
    def prevent_update
      raise ActiveRecord::ReadOnlyRecord, "Ledger entries are immutable and cannot be updated"
    end

    # Prevent deletion of ledger entries
    def prevent_destroy
      raise ActiveRecord::ReadOnlyRecord, "Ledger entries are immutable and cannot be deleted"
    end
  end
end

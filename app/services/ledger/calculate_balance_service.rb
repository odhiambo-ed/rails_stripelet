module Ledger
  class CalculateBalanceService
    def initialize(entity, currency, as_of = nil)
      @entity = entity
      @currency = currency
      @as_of = as_of || Time.current
    end

    def call
      Ledger::Entry
        .where(entity: @entity, currency: @currency)
        .where("created_at <= ?", @as_of)
        .sum(:amount_cents)
    end
  end
end

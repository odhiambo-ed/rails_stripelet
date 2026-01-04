class Customer < ApplicationRecord
  include Identifiable

  enum :currency, { usd: "usd", eur: "eur", gbp: "gbp", jpy: "jpy" }, prefix: true

  validates :email, presence: true, uniqueness: { scope: :deleted_at }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :currency, presence: true

  has_many :subscriptions, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :ledger_entries, as: :entity, dependent: :destroy

  def balance(currency = "usd")
    Ledger::CalculateBalanceService.new(self, currency).call
  end
end

require 'rails_helper'

RSpec.describe Ledger::Entry, type: :model do
  describe 'validations' do
    let(:customer) { create(:customer) }

    it { is_expected.to validate_presence_of(:idempotency_key) }
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:entry_type) }
    it { is_expected.to validate_presence_of(:entity_type) }
    it { is_expected.to validate_presence_of(:entity_id) }

    describe 'idempotency_key uniqueness' do
      let!(:existing_entry) { create(:ledger_entry, entity: customer) }

      it 'enforces unique idempotency_key' do
        duplicate = build(:ledger_entry, entity: customer, idempotency_key: existing_entry.idempotency_key)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:entity) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:entry_type).with_values(credit: 'credit', debit: 'debit', refund: 'refund', adjustment: 'adjustment', fee: 'fee').backed_by_column_of_type(:string) }
    it { is_expected.to define_enum_for(:currency).with_values(usd: 'usd', eur: 'eur', gbp: 'gbp', jpy: 'jpy').backed_by_column_of_type(:string) }
  end

  describe 'scopes' do
    let(:customer) { create(:customer) }
    let!(:credit_entry) { create(:ledger_entry, entity: customer, entry_type: :credit) }
    let!(:debit_entry) { create(:ledger_entry, entity: customer, entry_type: :debit) }
    let!(:old_entry) { create(:ledger_entry, entity: customer, created_at: 2.days.ago) }

    it '.for_entity returns entries for specific entity' do
      expect(Ledger::Entry.for_entity(customer)).to include(credit_entry, debit_entry)
    end

    it '.credits returns only credit entries' do
      expect(Ledger::Entry.credits).to include(credit_entry)
      expect(Ledger::Entry.credits).not_to include(debit_entry)
    end

    it '.debits returns only debit entries' do
      expect(Ledger::Entry.debits).to include(debit_entry)
      expect(Ledger::Entry.debits).not_to include(credit_entry)
    end

    it '.before returns entries before timestamp' do
      expect(Ledger::Entry.before(1.day.ago)).to include(old_entry)
      expect(Ledger::Entry.before(1.day.ago)).not_to include(credit_entry)
    end
  end

  describe 'immutability' do
    let(:customer) { create(:customer) }
    let(:entry) { create(:ledger_entry, entity: customer, amount_cents: 1000) }

    it 'prevents updates' do
      expect {
        entry.update!(amount_cents: 2000)
      }.to raise_error(ActiveRecord::ReadOnlyRecord, /Ledger entries are immutable/)
    end

    it 'prevents deletion' do
      expect {
        entry.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord, /Ledger entries are immutable/)
    end

    it 'allows creation' do
      new_entry = build(:ledger_entry, entity: customer)
      expect(new_entry.save).to be true
    end
  end
end

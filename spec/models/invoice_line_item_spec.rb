require 'rails_helper'

RSpec.describe InvoiceLineItem, type: :model do
  describe 'validations' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:invoice) { create(:invoice, customer: customer, subscription: subscription) }

    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_presence_of(:unit_amount_cents) }
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:invoice_id) }

    describe 'quantity validation' do
      let(:line_item) { build(:invoice_line_item, invoice: invoice) }

      it 'accepts positive quantity' do
        line_item.quantity = 5.5
        expect(line_item).to be_valid
      end

      it 'rejects zero quantity' do
        line_item.quantity = 0
        expect(line_item).not_to be_valid
      end

      it 'rejects negative quantity' do
        line_item.quantity = -2
        expect(line_item).not_to be_valid
      end
    end

    describe 'amount validations' do
      let(:line_item) { build(:invoice_line_item, invoice: invoice) }

      it 'accepts non-negative unit_amount_cents' do
        line_item.unit_amount_cents = 1000
        expect(line_item).to be_valid
      end

      it 'rejects negative unit_amount_cents' do
        line_item.unit_amount_cents = -100
        expect(line_item).not_to be_valid
      end

      it 'accepts non-negative amount_cents' do
        line_item.amount_cents = 5000
        expect(line_item).to be_valid
      end

      it 'rejects negative amount_cents' do
        line_item.amount_cents = -500
        expect(line_item).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:invoice) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:currency).with_values(usd: 'usd', eur: 'eur', gbp: 'gbp', jpy: 'jpy').backed_by_column_of_type(:string) }
  end

  describe 'cascade delete' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:invoice) { create(:invoice, customer: customer, subscription: subscription) }
    let!(:line_item) { create(:invoice_line_item, invoice: invoice) }

    it 'deletes line items when invoice is deleted' do
      expect { invoice.destroy }.to change(InvoiceLineItem, :count).by(-1)
      expect(InvoiceLineItem.exists?(line_item.id)).to be false
    end
  end

  describe '.by_currency scope' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:invoice) { create(:invoice, customer: customer, subscription: subscription) }
    let!(:usd_item) { create(:invoice_line_item, invoice: invoice, currency: :usd) }
    let!(:eur_item) { create(:invoice_line_item, invoice: invoice, currency: :eur) }
    let!(:gbp_item) { create(:invoice_line_item, invoice: invoice, currency: :gbp) }

    it 'returns line items for specified currency' do
      expect(InvoiceLineItem.by_currency('usd')).to include(usd_item)
      expect(InvoiceLineItem.by_currency('usd')).not_to include(eur_item)
      expect(InvoiceLineItem.by_currency('usd')).not_to include(gbp_item)
    end

    it 'returns all items for EUR currency' do
      expect(InvoiceLineItem.by_currency('eur')).to include(eur_item)
      expect(InvoiceLineItem.by_currency('eur')).not_to include(usd_item)
    end
  end

  describe 'amount calculation constraint' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:invoice) { create(:invoice, customer: customer, subscription: subscription) }

    it 'enforces amount_cents = quantity * unit_amount_cents' do
      # Valid: 5 * 1000 = 5000
      line_item = build(:invoice_line_item, invoice: invoice, quantity: 5, unit_amount_cents: 1000, amount_cents: 5000)
      expect(line_item).to be_valid
    end

    it 'rejects incorrect amount_cents calculation' do
      # Invalid: 5 * 1000 should be 5000, not 4000
      line_item = build(:invoice_line_item, invoice: invoice, quantity: 5, unit_amount_cents: 1000, amount_cents: 4000)
      expect { line_item.save! }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'handles decimal quantities correctly' do
      # Valid: 2.5 * 1000 = 2500
      line_item = build(:invoice_line_item, invoice: invoice, quantity: 2.5, unit_amount_cents: 1000, amount_cents: 2500)
      expect(line_item).to be_valid
    end
  end
end

require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe 'validations' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:subtotal_cents) }
    it { is_expected.to validate_presence_of(:tax_cents) }
    it { is_expected.to validate_presence_of(:total_cents) }
    it { is_expected.to validate_presence_of(:amount_paid_cents) }
    it { is_expected.to validate_presence_of(:amount_refunded_cents) }
    it { is_expected.to validate_presence_of(:amount_due_cents) }
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
    it { is_expected.to validate_presence_of(:customer_id) }
    it { is_expected.to validate_presence_of(:subscription_id) }

    describe 'amount validations' do
      let(:invoice) { build(:invoice, customer: customer, subscription: subscription) }

      it 'accepts non-negative amounts' do
        invoice.subtotal_cents = 1000
        invoice.tax_cents = 100
        invoice.total_cents = 1100
        invoice.amount_paid_cents = 500
        invoice.amount_refunded_cents = 0
        invoice.amount_due_cents = 600
        expect(invoice).to be_valid
      end

      it 'rejects negative subtotal_cents' do
        invoice.subtotal_cents = -100
        expect(invoice).not_to be_valid
      end

      it 'rejects negative tax_cents' do
        invoice.tax_cents = -50
        expect(invoice).not_to be_valid
      end
    end

    describe 'invoice_id uniqueness' do
      let!(:existing_invoice) { create(:invoice, customer: customer, subscription: subscription) }

      it 'enforces unique invoice_id' do
        duplicate = build(:invoice, customer: customer, subscription: subscription, invoice_id: existing_invoice.invoice_id)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:subscription) }
    it { is_expected.to have_many(:line_items).dependent(:destroy) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(draft: 'draft', open: 'open', paid: 'paid', void: 'void', uncollectible: 'uncollectible', partially_refunded: 'partially_refunded', refunded: 'refunded').backed_by_column_of_type(:string) }
    it { is_expected.to define_enum_for(:currency).with_values(usd: 'usd', eur: 'eur', gbp: 'gbp', jpy: 'jpy').backed_by_column_of_type(:string) }
  end

  describe '#generate_external_id' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }

    it 'generates invoice_id before creation' do
      invoice = build(:invoice, customer: customer, subscription: subscription)
      expect(invoice.invoice_id).to be_nil

      invoice.save
      expect(invoice.invoice_id).to start_with('inv_')
      expect(invoice.invoice_id.length).to eq(31)
    end

    it 'generates unique invoice_ids' do
      inv1 = create(:invoice, customer: customer, subscription: subscription)
      inv2 = create(:invoice, customer: customer, subscription: subscription)

      expect(inv1.invoice_id).not_to eq(inv2.invoice_id)
    end
  end

  describe '.open scope' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let!(:open_invoice) { create(:invoice, customer: customer, subscription: subscription, status: :open, deleted_at: nil) }
    let!(:paid_invoice) { create(:invoice, customer: customer, subscription: subscription, status: :paid, deleted_at: nil) }
    let!(:deleted_invoice) { create(:invoice, customer: customer, subscription: subscription, status: :open, deleted_at: 1.day.ago) }

    it 'returns only open and not deleted invoices' do
      expect(Invoice.open).to include(open_invoice)
      expect(Invoice.open).not_to include(paid_invoice)
      expect(Invoice.open).not_to include(deleted_invoice)
    end
  end

  describe '.paid scope' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let!(:paid_invoice) { create(:invoice, customer: customer, subscription: subscription, status: :paid, deleted_at: nil) }
    let!(:open_invoice) { create(:invoice, customer: customer, subscription: subscription, status: :open, deleted_at: nil) }
    let!(:deleted_paid) { create(:invoice, customer: customer, subscription: subscription, status: :paid, deleted_at: 1.day.ago) }

    it 'returns only paid and not deleted invoices' do
      expect(Invoice.paid).to include(paid_invoice)
      expect(Invoice.paid).not_to include(open_invoice)
      expect(Invoice.paid).not_to include(deleted_paid)
    end
  end

  describe '.overdue scope' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let!(:overdue_invoice) { create(:invoice, customer: customer, subscription: subscription, status: :open, due_date: 5.days.ago.to_date, deleted_at: nil) }
    let!(:not_overdue) { create(:invoice, customer: customer, subscription: subscription, status: :open, due_date: 5.days.from_now.to_date, deleted_at: nil) }
    let!(:paid_overdue) { create(:invoice, customer: customer, subscription: subscription, status: :paid, due_date: 5.days.ago.to_date, deleted_at: nil) }
    let!(:deleted_overdue) { create(:invoice, customer: customer, subscription: subscription, status: :open, due_date: 5.days.ago.to_date, deleted_at: 1.day.ago) }

    it 'returns only open invoices with due_date in past' do
      expect(Invoice.overdue).to include(overdue_invoice)
      expect(Invoice.overdue).not_to include(not_overdue)
      expect(Invoice.overdue).not_to include(paid_overdue)
      expect(Invoice.overdue).not_to include(deleted_overdue)
    end
  end

  describe '#finalize!' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:invoice) { create(:invoice, customer: customer, subscription: subscription, status: :draft, finalized_at: nil) }

    it 'changes status from draft to open' do
      invoice.finalize!
      expect(invoice.reload.status).to eq('open')
    end

    it 'sets finalized_at timestamp' do
      invoice.finalize!
      expect(invoice.reload.finalized_at).to be_present
    end

    it 'does not finalize twice' do
      invoice.finalize!
      first_finalized_at = invoice.reload.finalized_at

      travel 1.second
      invoice.finalize!

      expect(invoice.reload.finalized_at).to eq(first_finalized_at)
    end
  end

  describe '#mark_paid!' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:invoice) { create(:invoice, customer: customer, subscription: subscription, status: :open, amount_due_cents: 1000) }

    it 'changes status to paid' do
      invoice.mark_paid!
      expect(invoice.reload.status).to eq('paid')
    end

    it 'sets paid_at timestamp' do
      invoice.mark_paid!
      expect(invoice.reload.paid_at).to be_present
    end

    it 'sets amount_due_cents to zero' do
      invoice.mark_paid!
      expect(invoice.reload.amount_due_cents).to eq(0)
    end
  end

  describe '#readonly?' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }

    it 'returns false when not finalized' do
      invoice = create(:invoice, customer: customer, subscription: subscription, finalized_at: nil)
      expect(invoice.readonly?).to be false
    end

    it 'returns true when finalized' do
      invoice = create(:invoice, customer: customer, subscription: subscription, finalized_at: Time.current)
      expect(invoice.readonly?).to be true
    end

    it 'prevents updates after finalization' do
      invoice = create(:invoice, customer: customer, subscription: subscription, finalized_at: Time.current)
      expect { invoice.update!(total_cents: 5000) }.to raise_error(ActiveRecord::ReadonlyRecord)
    end
  end
end

require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:currency) }

    describe 'email validation' do
      let(:customer) { build(:customer) }

      it 'accepts valid email format' do
        customer.email = 'test@example.com'
        expect(customer).to be_valid
      end

      it 'rejects invalid email format' do
        customer.email = 'invalid-email'
        expect(customer).not_to be_valid
      end

      it 'enforces uniqueness of email' do
        create(:customer, email: 'unique@example.com')
        customer = build(:customer, email: 'unique@example.com')
        expect(customer).not_to be_valid
      end

      it 'allows duplicate email if previous is soft-deleted' do
        deleted_customer = create(:customer, email: 'reusable@example.com')
        deleted_customer.update(deleted_at: Time.current)

        new_customer = build(:customer, email: 'reusable@example.com')
        expect(new_customer).to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:invoices).dependent(:destroy) }
    it { is_expected.to have_many(:ledger_entries).dependent(:destroy) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:currency).with_values(usd: 'usd', eur: 'eur', gbp: 'gbp', jpy: 'jpy') }
  end

  describe '#generate_external_id' do
    it 'generates customer_id before creation' do
      customer = build(:customer)
      expect(customer.customer_id).to be_nil

      customer.save
      expect(customer.customer_id).to start_with('cus_')
      expect(customer.customer_id.length).to eq(31)
    end

    it 'generates unique customer_ids' do
      customer1 = create(:customer)
      customer2 = create(:customer)

      expect(customer1.customer_id).not_to eq(customer2.customer_id)
    end
  end

  describe '#balance' do
    let(:customer) { create(:customer, currency: :usd) }

    it 'returns balance for specified currency' do
      allow_any_instance_of(Ledger::CalculateBalanceService).to receive(:call).and_return(10000)

      result = customer.balance('usd')

      expect(result).to eq(10000)
    end

    it 'defaults to usd currency when not specified' do
      service_instance = instance_double(Ledger::CalculateBalanceService, call: 5000)
      allow(Ledger::CalculateBalanceService).to receive(:new).with(customer, 'usd').and_return(service_instance)

      result = customer.balance

      expect(result).to eq(5000)
    end
  end
end

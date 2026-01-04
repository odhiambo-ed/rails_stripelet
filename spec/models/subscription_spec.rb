require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'validations' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:current_period_start) }
    it { is_expected.to validate_presence_of(:current_period_end) }
    it { is_expected.to validate_presence_of(:next_billing_date) }
    it { is_expected.to validate_presence_of(:customer_id) }
    it { is_expected.to validate_presence_of(:price_id) }

    describe 'subscription_id uniqueness' do
      let!(:existing_sub) { create(:subscription, customer: customer, price: price) }

      it 'enforces unique subscription_id' do
        duplicate = build(:subscription, customer: customer, price: price, subscription_id: existing_sub.subscription_id)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:price) }
    it { is_expected.to have_many(:invoices).dependent(:destroy) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(trialing: 'trialing', active: 'active', past_due: 'past_due', canceled: 'canceled', paused: 'paused') }
  end

  describe '#generate_external_id' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }

    it 'generates subscription_id before creation' do
      subscription = build(:subscription, customer: customer, price: price)
      expect(subscription.subscription_id).to be_nil

      subscription.save
      expect(subscription.subscription_id).to start_with('sub_')
      expect(subscription.subscription_id.length).to eq(31)
    end

    it 'generates unique subscription_ids' do
      sub1 = create(:subscription, customer: customer, price: price)
      sub2 = create(:subscription, customer: customer, price: price)

      expect(sub1.subscription_id).not_to eq(sub2.subscription_id)
    end
  end

  describe '.active scope' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }
    let!(:active_sub) { create(:subscription, customer: customer, price: price, status: :active, deleted_at: nil) }
    let!(:trialing_sub) { create(:subscription, customer: customer, price: price, status: :trialing, deleted_at: nil) }
    let!(:canceled_sub) { create(:subscription, customer: customer, price: price, status: :canceled, deleted_at: nil) }
    let!(:deleted_sub) { create(:subscription, customer: customer, price: price, status: :active, deleted_at: 1.day.ago) }

    it 'returns only active and not deleted subscriptions' do
      expect(Subscription.active).to include(active_sub)
      expect(Subscription.active).not_to include(trialing_sub)
      expect(Subscription.active).not_to include(canceled_sub)
      expect(Subscription.active).not_to include(deleted_sub)
    end
  end

  describe '.trialing scope' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }
    let!(:trialing_sub) { create(:subscription, customer: customer, price: price, status: :trialing, deleted_at: nil) }
    let!(:active_sub) { create(:subscription, customer: customer, price: price, status: :active, deleted_at: nil) }
    let!(:deleted_trialing) { create(:subscription, customer: customer, price: price, status: :trialing, deleted_at: 1.day.ago) }

    it 'returns only trialing and not deleted subscriptions' do
      expect(Subscription.trialing).to include(trialing_sub)
      expect(Subscription.trialing).not_to include(active_sub)
      expect(Subscription.trialing).not_to include(deleted_trialing)
    end
  end

  describe '.due_for_renewal scope' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }
    let!(:due_active) { create(:subscription, customer: customer, price: price, status: :active, next_billing_date: Date.yesterday, deleted_at: nil) }
    let!(:due_trialing) { create(:subscription, customer: customer, price: price, status: :trialing, next_billing_date: Date.today, deleted_at: nil) }
    let!(:not_due) { create(:subscription, customer: customer, price: price, status: :active, next_billing_date: 5.days.from_now.to_date, deleted_at: nil) }
    let!(:canceled) { create(:subscription, customer: customer, price: price, status: :canceled, next_billing_date: Date.yesterday, deleted_at: nil) }
    let!(:deleted) { create(:subscription, customer: customer, price: price, status: :active, next_billing_date: Date.yesterday, deleted_at: 1.day.ago) }

    it 'returns subscriptions due for renewal (active/trialing with next_billing_date <= today)' do
      expect(Subscription.due_for_renewal).to include(due_active, due_trialing)
      expect(Subscription.due_for_renewal).not_to include(not_due)
      expect(Subscription.due_for_renewal).not_to include(canceled)
      expect(Subscription.due_for_renewal).not_to include(deleted)
    end
  end

  describe '#in_trial?' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }

    it 'returns true when status is trialing and trial_end_at is in future' do
      subscription = create(:subscription, customer: customer, price: price, status: :trialing, trial_end_at: 5.days.from_now)
      expect(subscription.in_trial?).to be true
    end

    it 'returns false when status is trialing but trial_end_at is in past' do
      subscription = create(:subscription, customer: customer, price: price, status: :trialing, trial_end_at: 5.days.ago)
      expect(subscription.in_trial?).to be false
    end

    it 'returns false when status is not trialing' do
      subscription = create(:subscription, customer: customer, price: price, status: :active, trial_end_at: 5.days.from_now)
      expect(subscription.in_trial?).to be false
    end

    it 'returns false when trial_end_at is nil' do
      subscription = create(:subscription, customer: customer, price: price, status: :trialing, trial_end_at: nil)
      expect(subscription.in_trial?).to be false
    end
  end

  describe '#days_until_renewal' do
    let(:customer) { create(:customer) }
    let(:price) { create(:price) }

    it 'returns positive days when renewal is in future' do
      subscription = create(:subscription, customer: customer, price: price, next_billing_date: 10.days.from_now.to_date)
      expect(subscription.days_until_renewal).to eq(10)
    end

    it 'returns zero when renewal is today' do
      subscription = create(:subscription, customer: customer, price: price, next_billing_date: Date.current)
      expect(subscription.days_until_renewal).to eq(0)
    end

    it 'returns negative days when renewal is in past' do
      subscription = create(:subscription, customer: customer, price: price, next_billing_date: 5.days.ago.to_date)
      expect(subscription.days_until_renewal).to eq(-5)
    end
  end
end

require 'rails_helper'

RSpec.describe SubscriptionUsageSummary, type: :model do
  describe 'validations' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }

    it { is_expected.to validate_presence_of(:subscription_id) }
    it { is_expected.to validate_presence_of(:metric) }
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
    it { is_expected.to validate_presence_of(:total_quantity) }

    describe 'uniqueness validation' do
      let!(:existing_summary) { create(:subscription_usage_summary, subscription: subscription, metric: 'api_calls', period_start: Date.current, period_end: 30.days.from_now.to_date) }

      it 'enforces unique metric per subscription and period' do
        duplicate = build(:subscription_usage_summary, subscription: subscription, metric: 'api_calls', period_start: Date.current, period_end: 30.days.from_now.to_date)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:subscription) }
  end

  describe 'scopes' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let!(:api_summary) { create(:subscription_usage_summary, subscription: subscription, metric: 'api_calls') }
    let!(:storage_summary) { create(:subscription_usage_summary, subscription: subscription, metric: 'storage_gb') }

    it '.by_metric filters by metric' do
      expect(SubscriptionUsageSummary.by_metric('api_calls')).to include(api_summary)
      expect(SubscriptionUsageSummary.by_metric('api_calls')).not_to include(storage_summary)
    end
  end

  describe '#increment_quantity!' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:summary) { create(:subscription_usage_summary, subscription: subscription, total_quantity: 100) }

    it 'increments the total quantity' do
      summary.increment_quantity!(50)
      expect(summary.reload.total_quantity).to eq(150)
    end

    it 'updates last_aggregated_at' do
      original_time = summary.last_aggregated_at
      travel 1.second
      summary.increment_quantity!(50)
      expect(summary.reload.last_aggregated_at).to be > original_time
    end
  end

  describe '#reset_quantity!' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:summary) { create(:subscription_usage_summary, subscription: subscription, total_quantity: 100) }

    it 'resets quantity to zero' do
      summary.reset_quantity!
      expect(summary.reload.total_quantity).to eq(0)
    end
  end
end

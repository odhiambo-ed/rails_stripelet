require 'rails_helper'

RSpec.describe UsageEvent, type: :model do
  describe 'validations' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }

    it { is_expected.to validate_presence_of(:event_id) }
    it { is_expected.to validate_presence_of(:subscription_id) }
    it { is_expected.to validate_presence_of(:metric_name) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_presence_of(:timestamp) }

    describe 'quantity validation' do
      let(:event) { build(:usage_event, subscription: subscription) }

      it 'accepts positive quantity' do
        event.quantity = 5.5
        expect(event).to be_valid
      end

      it 'rejects zero quantity' do
        event.quantity = 0
        expect(event).not_to be_valid
      end

      it 'rejects negative quantity' do
        event.quantity = -2
        expect(event).not_to be_valid
      end
    end

    describe 'event_id uniqueness' do
      let!(:existing_event) { create(:usage_event, subscription: subscription) }

      it 'enforces unique event_id' do
        duplicate = build(:usage_event, subscription: subscription, event_id: existing_event.event_id)
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
    let!(:unprocessed) { create(:usage_event, subscription: subscription, processed_at: nil) }
    let!(:processed) { create(:usage_event, subscription: subscription, processed_at: Time.current) }
    let!(:api_event) { create(:usage_event, subscription: subscription, metric_name: 'api_calls') }
    let!(:storage_event) { create(:usage_event, subscription: subscription, metric_name: 'storage_gb') }

    it '.unprocessed returns events without processed_at' do
      expect(UsageEvent.unprocessed).to include(unprocessed)
      expect(UsageEvent.unprocessed).not_to include(processed)
    end

    it '.processed returns events with processed_at' do
      expect(UsageEvent.processed).to include(processed)
      expect(UsageEvent.processed).not_to include(unprocessed)
    end

    it '.by_metric filters by metric name' do
      expect(UsageEvent.by_metric('api_calls')).to include(api_event)
      expect(UsageEvent.by_metric('api_calls')).not_to include(storage_event)
    end
  end

  describe '#mark_as_processed!' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }
    let(:event) { create(:usage_event, subscription: subscription, processed_at: nil) }

    it 'sets processed_at timestamp' do
      event.mark_as_processed!
      expect(event.reload.processed_at).to be_present
    end
  end

  describe '#processed?' do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer: customer) }

    it 'returns false when processed_at is nil' do
      event = create(:usage_event, subscription: subscription, processed_at: nil)
      expect(event.processed?).to be false
    end

    it 'returns true when processed_at is set' do
      event = create(:usage_event, subscription: subscription, processed_at: Time.current)
      expect(event.processed?).to be true
    end
  end
end

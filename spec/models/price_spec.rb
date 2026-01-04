require 'rails_helper'

RSpec.describe Price, type: :model do
  describe 'validations' do
    let(:product) { create(:product) }

    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:interval) }
    it { is_expected.to validate_presence_of(:interval_count) }
    it { is_expected.to validate_presence_of(:billing_scheme) }
    it { is_expected.to validate_presence_of(:product_id) }

    describe 'amount_cents validation' do
      let(:price) { build(:price, product: product) }

      it 'accepts positive amount_cents' do
        price.amount_cents = 2999
        expect(price).to be_valid
      end

      it 'rejects zero amount_cents' do
        price.amount_cents = 0
        expect(price).not_to be_valid
      end

      it 'rejects negative amount_cents' do
        price.amount_cents = -100
        expect(price).not_to be_valid
      end
    end

    describe 'interval_count validation' do
      let(:price) { build(:price, product: product) }

      it 'accepts positive interval_count' do
        price.interval_count = 3
        expect(price).to be_valid
      end

      it 'rejects zero interval_count' do
        price.interval_count = 0
        expect(price).not_to be_valid
      end

      it 'rejects negative interval_count' do
        price.interval_count = -1
        expect(price).not_to be_valid
      end
    end

    describe 'price_id uniqueness' do
      let!(:existing_price) { create(:price, product: product) }

      it 'enforces unique price_id' do
        duplicate = build(:price, product: product, price_id: existing_price.price_id)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to have_many(:subscriptions).dependent(:nullify) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:currency).with_values(usd: 'usd', eur: 'eur', gbp: 'gbp', jpy: 'jpy').backed_by_column_of_type(:string) }
    it { is_expected.to define_enum_for(:interval).with_values(day: 'day', week: 'week', month: 'month', year: 'year').backed_by_column_of_type(:string) }
    it { is_expected.to define_enum_for(:billing_scheme).with_values(per_unit: 'per_unit', tiered: 'tiered').backed_by_column_of_type(:string) }
  end

  describe '#generate_external_id' do
    let(:product) { create(:product) }

    it 'generates price_id before creation' do
      price = build(:price, product: product)
      expect(price.price_id).to be_nil

      price.save
      expect(price.price_id).to start_with('pri_')
      expect(price.price_id.length).to eq(31)
    end

    it 'generates unique price_ids' do
      price1 = create(:price, product: product)
      price2 = create(:price, product: product)

      expect(price1.price_id).not_to eq(price2.price_id)
    end
  end

  describe '.active scope' do
    let(:product) { create(:product) }
    let!(:active_price) { create(:price, product: product, active: true, deleted_at: nil) }
    let!(:inactive_price) { create(:price, product: product, active: false, deleted_at: nil) }
    let!(:deleted_price) { create(:price, product: product, active: true, deleted_at: 1.day.ago) }

    it 'returns only active and not deleted prices' do
      expect(Price.active).to include(active_price)
      expect(Price.active).not_to include(inactive_price)
      expect(Price.active).not_to include(deleted_price)
    end

    it 'returns empty array when no active prices exist' do
      Price.destroy_all
      expect(Price.active).to be_empty
    end
  end
end

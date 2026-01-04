require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:product_id) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:prices).dependent(:destroy) }
  end

  describe '#generate_external_id' do
    it 'generates product_id before creation' do
      product = build(:product)
      expect(product.product_id).to be_nil

      product.save
      expect(product.product_id).to start_with('pro_')
      expect(product.product_id.length).to eq(31)
    end

    it 'generates unique product_ids' do
      product1 = create(:product)
      product2 = create(:product)

      expect(product1.product_id).not_to eq(product2.product_id)
    end
  end

  describe '.active scope' do
    let!(:active_product) { create(:product, active: true, deleted_at: nil) }
    let!(:inactive_product) { create(:product, active: false, deleted_at: nil) }
    let!(:deleted_product) { create(:product, active: true, deleted_at: 1.day.ago) }

    it 'returns only active and not deleted products' do
      expect(Product.active).to include(active_product)
      expect(Product.active).not_to include(inactive_product)
      expect(Product.active).not_to include(deleted_product)
    end

    it 'returns empty array when no active products exist' do
      Product.destroy_all
      expect(Product.active).to be_empty
    end
  end
end

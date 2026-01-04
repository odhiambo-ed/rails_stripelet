module Identifiable
  extend ActiveSupport::Concern

  included do
    before_create :generate_external_id
  end

  private

  def generate_external_id
    prefix = self.class.name.downcase[0..2]
    self.send("#{prefix[0..2]}_id=", "#{prefix}_#{SecureRandom.hex(12)}")
  end
end

module Identifiable
  extend ActiveSupport::Concern

  included do
    before_create :generate_external_id
  end

  private

  def generate_external_id
    # Extract model name (e.g., "Customer" -> "customer", "Invoice" -> "invoice")
    model_name = self.class.name.demodulize.underscore
    prefix = model_name[0..2]

    # Set the external ID (e.g., customer_id, invoice_id)
    self.send("#{model_name}_id=", "#{prefix}_#{SecureRandom.hex(12)}")
  end
end

# ApiKey manages API authentication keys with role-based permissions
class ApiKey < ApplicationRecord
  include Identifiable

  # Enums
  enum :role, { admin: "admin", finance: "finance", standard: "standard", read_only: "read_only" }, prefix: true

  # Validations
  validates :key_id, uniqueness: true
  validates :key_digest, presence: true
  validates :role, presence: true
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where.not(expires_at: nil).where("expires_at <= ?", Time.current) }
  scope :by_role, ->(role) { where(role: role) }

  # Check if key is active (not revoked and not expired)
  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  # Revoke this key
  def revoke!
    update!(revoked_at: Time.current)
  end

  # Update last used timestamp
  def record_usage!
    touch(:last_used_at)
  end

  # Check if key is expired
  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # Check if key is revoked
  def revoked?
    revoked_at.present?
  end
end

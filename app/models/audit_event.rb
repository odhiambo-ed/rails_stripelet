# AuditEvent tracks all significant actions in the system for compliance and debugging
class AuditEvent < ApplicationRecord
  include Identifiable

  # Enums
  enum :action, {
    create: "create",
    update: "update",
    delete: "delete",
    view: "view",
    export: "export",
    login: "login",
    logout: "logout"
  }, prefix: true

  # Polymorphic associations
  belongs_to :actor, polymorphic: true
  belongs_to :subject, polymorphic: true

  # Validations
  validates :event_id, uniqueness: true
  validates :actor_type, presence: true
  validates :actor_id, presence: true
  validates :subject_type, presence: true
  validates :subject_id, presence: true
  validates :action, presence: true

  # Scopes
  scope :by_actor, ->(actor) { where(actor: actor) }
  scope :by_subject, ->(subject) { where(subject: subject) }
  scope :by_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }
  scope :in_period, ->(start_time, end_time) { where(created_at: start_time..end_time) }

  # Get human-readable description of the event
  def description
    "#{actor_type} #{actor_id} #{action}d #{subject_type} #{subject_id}"
  end
end

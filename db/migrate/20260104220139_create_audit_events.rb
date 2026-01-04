class CreateAuditEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_events do |t|
      # Unique event identifier
      t.string :event_id, null: false

      # Who performed the action (polymorphic: User, ApiKey, etc.)
      t.references :actor, polymorphic: true, null: false

      # What was acted upon (polymorphic: Customer, Invoice, Subscription, etc.)
      t.references :subject, polymorphic: true, null: false

      # Action performed (create, update, delete, etc.)
      t.string :action, null: false

      # Data that changed (before/after values)
      t.jsonb :change_data, default: {}, null: false

      # IP address of the actor
      t.inet :ip_address

      # Additional audit data
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :audit_events, :event_id, unique: true
    add_index :audit_events, [ :actor_type, :actor_id ]
    add_index :audit_events, [ :subject_type, :subject_id ]
    add_index :audit_events, :action
    add_index :audit_events, :created_at

    # Composite index for actor queries
    add_index :audit_events, [ :actor_type, :actor_id, :created_at ],
              name: "idx_audit_events_actor_time"

    # Composite index for subject queries
    add_index :audit_events, [ :subject_type, :subject_id, :created_at ],
              name: "idx_audit_events_subject_time"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :audit_events,
      "action IN ('create', 'update', 'delete', 'view', 'export', 'login', 'logout')",
      name: "chk_audit_event_action_valid"

    # =====================
    # Comments
    # =====================
    change_table_comment :audit_events,
      "Audit trail of all significant actions in the system"

    change_column_comment :audit_events, :event_id,
      "Unique audit event identifier (aud_xxx)"

    change_column_comment :audit_events, :actor_type,
      "Type of entity that performed the action (User, ApiKey, etc.)"

    change_column_comment :audit_events, :actor_id,
      "ID of the entity that performed the action"

    change_column_comment :audit_events, :subject_type,
      "Type of entity that was acted upon (Customer, Invoice, etc.)"

    change_column_comment :audit_events, :subject_id,
      "ID of the entity that was acted upon"

    change_column_comment :audit_events, :action,
      "Action performed (create, update, delete, view, export, login, logout)"

    change_column_comment :audit_events, :change_data,
      "Before/after values for the change"

    change_column_comment :audit_events, :ip_address,
      "IP address from which the action was performed"
  end
end

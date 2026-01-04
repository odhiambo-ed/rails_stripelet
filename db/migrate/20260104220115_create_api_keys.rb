class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      # Unique key identifier (visible part of the key)
      t.string :key_id, null: false

      # Bcrypt hashed key digest (NOT the plain text key)
      t.string :key_digest, null: false

      # Role/permission level (admin, finance, standard, read_only)
      t.string :role, null: false

      # Human-readable name for this key
      t.string :name, null: false

      # Last time this key was used
      t.datetime :last_used_at

      # When this key expires (null = never expires)
      t.datetime :expires_at

      # When this key was revoked (null = active)
      t.datetime :revoked_at

      # Additional key metadata
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :api_keys, :key_id, unique: true
    add_index :api_keys, :role
    add_index :api_keys, :revoked_at
    add_index :api_keys, :expires_at

    # Index for finding non-revoked keys (expiration check done in application)
    add_index :api_keys,
              :key_id,
              where: "revoked_at IS NULL",
              name: "idx_api_keys_active"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :api_keys,
      "role IN ('admin', 'finance', 'standard', 'read_only')",
      name: "chk_api_key_role_valid"

    add_check_constraint :api_keys,
      "name != ''",
      name: "chk_api_key_name_not_empty"

    # =====================
    # Comments
    # =====================
    change_table_comment :api_keys,
      "API keys for authentication - key_digest is hashed, never store plain text"

    change_column_comment :api_keys, :key_id,
      "Public part of the API key (sk_xxx)"

    change_column_comment :api_keys, :key_digest,
      "Bcrypt hash of the secret key - NEVER store plain text keys"

    change_column_comment :api_keys, :role,
      "Permission level (admin, finance, standard, read_only)"

    change_column_comment :api_keys, :name,
      "Human-readable name for this key"

    change_column_comment :api_keys, :last_used_at,
      "Last time this key was used for authentication"

    change_column_comment :api_keys, :expires_at,
      "When this key expires (null = never expires)"

    change_column_comment :api_keys, :revoked_at,
      "When this key was revoked (null = still active)"
  end
end

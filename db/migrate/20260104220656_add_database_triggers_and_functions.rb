class AddDatabaseTriggersAndFunctions < ActiveRecord::Migration[8.0]
  def up
    # =====================
    # 1. Ledger Entry Immutability Triggers
    # =====================
    execute <<~SQL
      -- Function to prevent updates to ledger entries
      CREATE OR REPLACE FUNCTION prevent_ledger_mutation()
      RETURNS TRIGGER AS $$
      BEGIN
        RAISE EXCEPTION 'Ledger entries are immutable and cannot be modified or deleted';
      END;
      $$ LANGUAGE plpgsql;

      -- Trigger to prevent updates
      CREATE TRIGGER trigger_prevent_ledger_update
      BEFORE UPDATE ON ledger_entries
      FOR EACH ROW
      EXECUTE FUNCTION prevent_ledger_mutation();

      -- Trigger to prevent deletes
      CREATE TRIGGER trigger_prevent_ledger_delete
      BEFORE DELETE ON ledger_entries
      FOR EACH ROW
      EXECUTE FUNCTION prevent_ledger_mutation();
    SQL

    # =====================
    # 2. Invoice Finalization Lock Triggers
    # =====================
    execute <<~SQL
      -- Function to prevent modifications to finalized invoices
      CREATE OR REPLACE FUNCTION prevent_finalized_invoice_mutation()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Allow delete for soft delete pattern
        IF (TG_OP = 'DELETE') THEN
          RETURN OLD;
        END IF;

        -- For updates, check if invoice is finalized
        IF (OLD.finalized_at IS NOT NULL) THEN
          RAISE EXCEPTION 'Cannot modify finalized invoices';
        END IF;
      #{'  '}
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      -- Trigger to prevent updates to finalized invoices
      CREATE TRIGGER trigger_prevent_finalized_invoice_update
      BEFORE UPDATE ON invoices
      FOR EACH ROW
      EXECUTE FUNCTION prevent_finalized_invoice_mutation();
    SQL

    # =====================
    # 3. Refund Validation Trigger
    # =====================
    execute <<~SQL
      -- Function to validate refund amount doesn't exceed invoice total
      CREATE OR REPLACE FUNCTION validate_refund_amount()
      RETURNS TRIGGER AS $$
      DECLARE
        invoice_total BIGINT;
        total_refunded BIGINT;
      BEGIN
        -- Get the invoice total
        SELECT total_cents INTO invoice_total
        FROM invoices
        WHERE id = NEW.invoice_id;

        -- Get sum of existing refunds for this invoice (excluding current refund if update)
        SELECT COALESCE(SUM(amount_cents), 0) INTO total_refunded
        FROM refunds
        WHERE invoice_id = NEW.invoice_id
          AND id != COALESCE(NEW.id, -1);

        -- Check if new refund would exceed invoice total
        IF (total_refunded + NEW.amount_cents > invoice_total) THEN
          RAISE EXCEPTION 'Refund amount (% + %) exceeds invoice total (%)',#{' '}
            total_refunded, NEW.amount_cents, invoice_total;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      -- Trigger to validate refund amount on insert
      CREATE TRIGGER trigger_validate_refund_amount
      BEFORE INSERT ON refunds
      FOR EACH ROW
      EXECUTE FUNCTION validate_refund_amount();
    SQL

    # =====================
    # 4. Subscription Status Transition Validation
    # =====================
    execute <<~SQL
      -- Function to validate subscription status transitions
      CREATE OR REPLACE FUNCTION validate_subscription_status_transition()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Allow any transition on insert
        IF (TG_OP = 'INSERT') THEN
          RETURN NEW;
        END IF;

        -- If status hasn't changed, allow the update
        IF (OLD.status = NEW.status) THEN
          RETURN NEW;
        END IF;

        -- Validate specific transitions
        -- trialing -> active, canceled, past_due
        IF (OLD.status = 'trialing' AND NEW.status NOT IN ('active', 'canceled', 'past_due')) THEN
          RAISE EXCEPTION 'Invalid transition from trialing to %', NEW.status;
        END IF;

        -- active -> past_due, canceled, paused
        IF (OLD.status = 'active' AND NEW.status NOT IN ('past_due', 'canceled', 'paused')) THEN
          RAISE EXCEPTION 'Invalid transition from active to %', NEW.status;
        END IF;

        -- past_due -> active, canceled
        IF (OLD.status = 'past_due' AND NEW.status NOT IN ('active', 'canceled')) THEN
          RAISE EXCEPTION 'Invalid transition from past_due to %', NEW.status;
        END IF;

        -- paused -> active, canceled
        IF (OLD.status = 'paused' AND NEW.status NOT IN ('active', 'canceled')) THEN
          RAISE EXCEPTION 'Invalid transition from paused to %', NEW.status;
        END IF;

        -- canceled is terminal - no transitions allowed
        IF (OLD.status = 'canceled') THEN
          RAISE EXCEPTION 'Cannot transition from canceled status';
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      -- Trigger to validate subscription status transitions
      CREATE TRIGGER trigger_validate_subscription_status_transition
      BEFORE UPDATE ON subscriptions
      FOR EACH ROW
      EXECUTE FUNCTION validate_subscription_status_transition();
    SQL

    # =====================
    # 5. Advisory Lock Function for Subscription Billing
    # =====================
    execute <<~SQL
      -- Drop existing functions if they exist (from old migrations)
      DROP FUNCTION IF EXISTS acquire_subscription_billing_lock(BIGINT);
      DROP FUNCTION IF EXISTS release_subscription_billing_lock(BIGINT);

      -- Function to acquire an advisory lock for subscription billing
      CREATE FUNCTION acquire_subscription_billing_lock(subscription_id_param BIGINT)
      RETURNS BOOLEAN AS $$
      BEGIN
        -- Try to acquire an advisory lock using the subscription ID
        -- Returns true if lock was acquired, false if already locked
        RETURN pg_try_advisory_lock(42, subscription_id_param);
      END;
      $$ LANGUAGE plpgsql;

      -- Function to release the advisory lock
      CREATE FUNCTION release_subscription_billing_lock(subscription_id_param BIGINT)
      RETURNS BOOLEAN AS $$
      BEGIN
        -- Release the advisory lock
        RETURN pg_advisory_unlock(42, subscription_id_param);
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    # Drop triggers first, then functions
    execute <<~SQL
      -- Drop ledger entry triggers and function
      DROP TRIGGER IF EXISTS trigger_prevent_ledger_update ON ledger_entries;
      DROP TRIGGER IF EXISTS trigger_prevent_ledger_delete ON ledger_entries;
      DROP FUNCTION IF EXISTS prevent_ledger_mutation();

      -- Drop invoice finalization trigger and function
      DROP TRIGGER IF EXISTS trigger_prevent_finalized_invoice_update ON invoices;
      DROP FUNCTION IF EXISTS prevent_finalized_invoice_mutation();

      -- Drop refund validation trigger and function
      DROP TRIGGER IF EXISTS trigger_validate_refund_amount ON refunds;
      DROP FUNCTION IF EXISTS validate_refund_amount();

      -- Drop subscription status transition trigger and function
      DROP TRIGGER IF EXISTS trigger_validate_subscription_status_transition ON subscriptions;
      DROP FUNCTION IF EXISTS validate_subscription_status_transition();

      -- Drop advisory lock functions
      DROP FUNCTION IF EXISTS acquire_subscription_billing_lock(BIGINT);
      DROP FUNCTION IF EXISTS release_subscription_billing_lock(BIGINT);
    SQL
  end
end

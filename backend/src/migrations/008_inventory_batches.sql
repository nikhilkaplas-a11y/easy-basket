-- ============================================================================
-- Migration 008: Bulk inventory editing — audit trail
--
-- Two tables recording every spreadsheet upload and every individual value it
-- changed.
--
--   inventory_batches      one row per upload
--   inventory_adjustments  one row per field actually changed
--
-- Why this exists at all, given the feature would "work" without it:
--
--   1. It answers "why does milk say 12?" three weeks later. Without it, a bulk
--      edit is indistinguishable from a bug.
--   2. It is what makes moving to chunked or background processing easy later.
--      At 400 products an upload is applied in one request; near 10,000 it has
--      to be split so it stops blocking checkout. Having a batch row from day
--      one turns that into a small change instead of a rewrite.
--   3. It is the seed of real inventory management. If every stock movement —
--      orders, cancellations, wastage — eventually writes here too, stock
--      becomes a derived number rather than a mutable column, and questions
--      like "what did we lose to spoilage in March?" become queries.
--
-- ----------------------------------------------------------------------------
-- Naming is EXPLICIT on both sides
-- ----------------------------------------------------------------------------
-- The entities declare @Entity({ name: 'inventory_batches' }) and every column
-- declares its own @Column({ name: ... }). That is deliberate: migration 006
-- was written in snake_case while its entity used TypeORM's camelCase defaults,
-- so the table and the code disagreed on almost every identifier and the
-- feature was dead for months. Pinning both ends removes that whole class of
-- error.
--
-- Note `user` is SINGULAR in this schema — 004 and 006 both referenced a
-- non-existent `users` and their foreign keys silently never applied.
--
-- ----------------------------------------------------------------------------
-- DEPLOY ORDER
-- ----------------------------------------------------------------------------
-- Run this BEFORE deploying the code. synchronize is false and TypeORM selects
-- mapped columns by name, so an entity whose table does not exist breaks any
-- query touching it. Running this against the CURRENT code is inert — nothing
-- reads these tables yet.
--
-- Additive and idempotent. Safe to run twice.
--
-- Run with:
--   mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p $DB_NAME < 008_inventory_batches.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS inventory_batches (
    id            INT NOT NULL AUTO_INCREMENT PRIMARY KEY,

    -- Who uploaded it. RESTRICT rather than CASCADE: deleting an admin must not
    -- erase the history of what they changed.
    actorUserId   INT NOT NULL,

    -- 'csv' today. Leaves room for 'admin_ui' if the in-app grid gets built.
    source        VARCHAR(32)  NOT NULL DEFAULT 'csv',

    -- 'applied' | 'failed'. A preview writes nothing, so there is no
    -- 'previewed' state — only uploads that actually tried to change data.
    status        VARCHAR(32)  NOT NULL,

    rowCount      INT NOT NULL DEFAULT 0,
    changedCount  INT NOT NULL DEFAULT 0,
    errorCount    INT NOT NULL DEFAULT 0,

    -- Free text shown back to the admin when something went wrong.
    note          VARCHAR(500) NULL DEFAULT NULL,

    createdAt     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT fk_inventory_batch_actor
        FOREIGN KEY (actorUserId) REFERENCES user(id),

    KEY idx_inventory_batch_created (createdAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS inventory_adjustments (
    id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,

    batchId      INT NOT NULL,

    productId    INT NOT NULL,
    -- NULL when the change was at product level (a product with no sizes, or
    -- the availability flag on a product that has them).
    variantId    INT NULL DEFAULT NULL,

    -- 'stock' | 'price' | 'available'
    field        VARCHAR(16) NOT NULL,

    -- Stored as text so one table holds integers, decimals and YES/NO without
    -- three sets of nullable typed columns. This is a human-readable audit
    -- log, never a source of computation.
    beforeValue  VARCHAR(64) NULL DEFAULT NULL,
    afterValue   VARCHAR(64) NULL DEFAULT NULL,

    createdAt    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT fk_inventory_adjustment_batch
        FOREIGN KEY (batchId) REFERENCES inventory_batches(id) ON DELETE CASCADE,

    -- No foreign keys to product / product_variant on purpose: the audit must
    -- survive a product being deleted. A dangling id is still evidence of what
    -- happened; a cascade-deleted audit row is not.
    KEY idx_inventory_adjustment_batch (batchId),
    KEY idx_inventory_adjustment_product (productId, createdAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------------------
-- Marker, consistent with 006 / 007.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schema_migrations (
  name       VARCHAR(128) NOT NULL PRIMARY KEY,
  applied_at DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO schema_migrations (name) VALUES ('008_inventory_batches');

-- ============================================================================
-- Done. Creates two empty tables; no existing row is read or written.
--
-- Rollback:
--   DROP TABLE inventory_adjustments;
--   DROP TABLE inventory_batches;
--   DELETE FROM schema_migrations WHERE name = '008_inventory_batches';
-- ============================================================================

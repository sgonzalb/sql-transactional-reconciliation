-- ============================================================================
-- 1. DDL: SCHEMA & INDEXES (Batch Ledger + Audit Log)
-- ============================================================================
CREATE TABLE batch_transactions (
    transaction_id   VARCHAR(20) PRIMARY KEY,
    batch_id         VARCHAR(20) NOT NULL,
    account_number   VARCHAR(15) NOT NULL,
    amount           NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    currency         CHAR(3) NOT NULL CHECK (currency IN ('PYG', 'USD')),
    status           VARCHAR(15) NOT NULL CHECK (status IN ('APPROVED', 'REJECTED', 'PENDING', 'REPROCESSED')),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at     TIMESTAMP
);

CREATE TABLE batch_audit_log (
    audit_id         SERIAL PRIMARY KEY,
    batch_id         VARCHAR(20) NOT NULL,
    action_type      VARCHAR(30) NOT NULL,
    affected_rows    INT NOT NULL,
    executed_by      VARCHAR(50) NOT NULL,
    executed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_batch_status ON batch_transactions (batch_id, status);

-- ============================================================================
-- 2. DML (INSERT): SAMPLE BATCH INGESTION
-- ============================================================================
INSERT INTO batch_transactions (transaction_id, batch_id, account_number, amount, currency, status, created_at)
VALUES
    ('TXN-1001', 'BATCH-20261112', '10045892', 3500000.00, 'PYG', 'PENDING', CURRENT_TIMESTAMP - INTERVAL '10 minutes'),
    ('TXN-1002', 'BATCH-20261112', '10045893', 2850000.00, 'PYG', 'PENDING', CURRENT_TIMESTAMP - INTERVAL '8 minutes'),
    ('TXN-1003', 'BATCH-20261112', '10045893', 2850000.00, 'PYG', 'PENDING', CURRENT_TIMESTAMP - INTERVAL '7 minutes'), -- Duplicate
    ('TXN-1004', 'BATCH-20261112', '10045895',     450.50, 'USD', 'REJECTED', CURRENT_TIMESTAMP - INTERVAL '6 minutes'),
    ('TXN-9999', 'BATCH-TEST-001', '00000000',     100.00, 'PYG', 'PENDING', CURRENT_TIMESTAMP - INTERVAL '1 day');

-- ============================================================================
-- 3. TRANSACTIONAL UPDATE: APPROVE PENDING RECORDS & LOG AUDIT TRAIL
-- ============================================================================
BEGIN;

UPDATE batch_transactions
SET
    status = 'APPROVED',
    processed_at = CURRENT_TIMESTAMP
WHERE batch_id = 'BATCH-20261112'
  AND status = 'PENDING'
  AND transaction_id NOT IN (
      -- Exclude duplicate entries before approving
      SELECT transaction_id
      FROM (
          SELECT
              transaction_id,
              ROW_NUMBER() OVER (
                  PARTITION BY batch_id, account_number, amount, currency
                  ORDER BY created_at ASC
              ) AS rn
          FROM batch_transactions
          WHERE batch_id = 'BATCH-20261112'
      ) sub
      WHERE rn > 1
  );

INSERT INTO batch_audit_log (batch_id, action_type, affected_rows, executed_by)
VALUES ('BATCH-20261112', 'BATCH_APPROVAL_UPDATE', 2, 'prod_admin_svc');

COMMIT;

-- ============================================================================
-- 4. CONTROLLED UPDATE: REPROCESS FAILED / REJECTED TRANSACTIONS
-- ============================================================================
UPDATE batch_transactions
SET
    status = 'REPROCESSED',
    processed_at = CURRENT_TIMESTAMP
WHERE batch_id = 'BATCH-20261112'
  AND status = 'REJECTED';

-- ============================================================================
-- 5. SAFE DELETE: PURGE TEST / STAGING BATCHES WITH ROLLBACK GUARD
-- ============================================================================
BEGIN;

DELETE FROM batch_transactions
WHERE batch_id LIKE 'BATCH-TEST-%'
  AND created_at < CURRENT_TIMESTAMP - INTERVAL '12 hours';

INSERT INTO batch_audit_log (batch_id, action_type, affected_rows, executed_by)
VALUES ('BATCH-TEST-001', 'TEST_DATA_CLEANUP', 1, 'prod_admin_svc');

-- Use ROLLBACK during dry-run verification, or COMMIT in production execution
COMMIT;

-- ============================================================================
-- 6. RECONCILIATION & SLA REPORTING (SELECT + JOIN + AGGREGATIONS)
-- ============================================================================
SELECT
    t.batch_id,
    t.currency,
    t.status,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_amount,
    MAX(a.executed_at) AS last_audit_timestamp
FROM batch_transactions t
LEFT JOIN batch_audit_log a
    ON t.batch_id = a.batch_id
GROUP BY t.batch_id, t.currency, t.status
ORDER BY t.batch_id DESC, t.currency, t.status;

/* =========================================================
   SCRIPT 9: PERFORMANCE, INDEXING & TRANSACTIONS (FIXED)
   ========================================================= */

USE northstar_finance;

/* ---------------------------
   1. Index optimization
   --------------------------- */

/* Keep useful composite index */
CREATE INDEX idx_orders_customer_date 
ON orders (customer_id, order_date);

/* Keep if filtering by status frequently */
CREATE INDEX idx_orders_status_date 
ON orders (order_status, order_date);

/* Payments lookup optimization */
CREATE INDEX idx_payments_order_status 
ON payments (order_id, payment_status);

/* Transactions lookup */
CREATE INDEX idx_transactions_account_date 
ON transactions (account_id, transaction_date);

/* Simplified index (remove bloat) */
CREATE INDEX idx_order_items_order_product 
ON order_items (order_id, product_id);


/* ---------------------------
   2. Query optimization checks
   --------------------------- */

/* Good: uses index */
EXPLAIN
SELECT
    o.order_number,
    o.order_date,
    o.total_amount
FROM orders o
WHERE o.customer_id = 1
  AND o.order_date >= '2025-01-01'
ORDER BY o.order_date;

/* FIXED: remove YEAR() */
EXPLAIN
SELECT *
FROM orders
WHERE order_date >= '2025-01-01'
  AND order_date < '2026-01-01';

/* Duplicate removed (was redundant) */


/* ---------------------------
   3. Transaction safety (fixed logic)
   --------------------------- */

START TRANSACTION;

/* Ensure sufficient balance */
UPDATE accounts
SET balance = balance - 176.40
WHERE account_id = 1
  AND balance >= 176.40;

/* Check if update worked */
SELECT ROW_COUNT() AS rows_updated;

SAVEPOINT after_debit;

/* Insert transaction record */
INSERT INTO transactions (
    account_id,
    transaction_date,
    transaction_type,
    amount,
    reference_code,
    narration
)
VALUES (
    1,
    NOW(),
    'debit',
    176.40,
    'TXN-DEMO-001',
    'Practice debit entry'
);

/* Example rollback scenario */
-- ROLLBACK TO SAVEPOINT after_debit;

/* If rollback happens, no manual reversal needed */

COMMIT;


/* ---------------------------
   4. Isolation level usage
   --------------------------- */

SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;
SELECT balance 
FROM accounts 
WHERE account_id = 1;
COMMIT;

/* Locking read */
START TRANSACTION;
SELECT * 
FROM accounts 
WHERE account_id = 1 
FOR UPDATE;
COMMIT;


/* ---------------------------
   5. Table statistics
   --------------------------- */

SELECT
    table_name,
    table_rows
FROM information_schema.tables
WHERE table_schema = 'northstar_finance'
ORDER BY table_rows DESC;
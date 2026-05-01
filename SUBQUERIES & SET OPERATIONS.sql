/* =========================================================
   SCRIPT 5: SUBQUERIES & SET OPERATIONS
   Purpose: Advanced filtering and reusable result sets.
   ========================================================= */

USE northstar_finance;

-- 1. Orders above average total amount (optimized)
WITH avg_order AS (
    SELECT AVG(total_amount) AS avg_amt FROM orders
)
SELECT
    o.order_number,
    o.total_amount
FROM orders o
JOIN avg_order a ON o.total_amount > a.avg_amt
ORDER BY o.total_amount DESC;

-- 2. Customer total spend (replaced correlated subquery with JOIN)
SELECT
    c.customer_id,
    c.legal_name,
    COALESCE(SUM(o.total_amount), 0) AS total_spend
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.legal_name
ORDER BY total_spend DESC;

-- 3. Customers with at least one settled payment (correct use of EXISTS)
SELECT
    c.customer_id,
    c.legal_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    JOIN payments p ON p.order_id = o.order_id
    WHERE o.customer_id = c.customer_id
      AND p.payment_status = 'settled'
);

-- 4. Customers with NO orders (FIXED LOGIC)
SELECT
    c.customer_id,
    c.legal_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- 5. Products priced above their category average (correct)
SELECT
    p.product_name,
    p.unit_price,
    avg_prices.avg_category_price
FROM products p
JOIN (
    SELECT
        category_id,
        AVG(unit_price) AS avg_category_price
    FROM products
    GROUP BY category_id
) avg_prices
    ON avg_prices.category_id = p.category_id
WHERE p.unit_price > avg_prices.avg_category_price;


-- 6. Accounts where balance exceeds customer's average order (NULL-safe)
SELECT
    a.account_number,
    a.balance
FROM accounts a
WHERE a.balance > COALESCE((
    SELECT AVG(o.total_amount)
    FROM orders o
    WHERE o.customer_id = a.customer_id
), 0);


-- 6. Accounts where balance exceeds customer's average order (NULL-safe)
SELECT
    a.account_number,
    a.balance
FROM accounts a
WHERE a.balance > COALESCE((
    SELECT AVG(o.total_amount)
    FROM orders o
    WHERE o.customer_id = a.customer_id
), 0);


-- 8. Combine customers and advisors (FIXED: avoid accidental deduplication)
SELECT
    legal_name AS person_name,
    'customer' AS entity_type
FROM customers
WHERE status = 'active'

UNION ALL

SELECT
    full_name AS person_name,
    'advisor' AS entity_type
FROM advisors
WHERE active_flag = 1;

-- 9. Unified event timeline (orders + payments)
SELECT
    order_number AS event_ref,
    'order' AS event_type,
    order_date AS event_date
FROM orders

UNION ALL

SELECT
    payment_reference AS event_ref,
    'payment' AS event_type,
    payment_date AS event_date
FROM payments;

-- 10. Conditional filtering with clearer structure
SELECT
    o.order_number,
    o.total_amount,
    o.order_status
FROM orders o
WHERE
    (o.order_status = 'fulfilled' AND o.total_amount >= 200)
    OR
    (o.order_status = 'confirmed' AND o.total_amount >= 100);
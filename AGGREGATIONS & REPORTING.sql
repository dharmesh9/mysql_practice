/* =========================================================
   SCRIPT 3: AGGREGATIONS & REPORTING
   Purpose: Summaries, KPIs, and management reporting.
   ========================================================= */

USE northstar_finance;

-- =========================================================
-- 1. CORE ENTITY COUNTS 
-- =========================================================
SELECT
    (SELECT COUNT(*) FROM customers) AS customer_count,
    (SELECT COUNT(*) FROM accounts) AS account_count,
    (SELECT COUNT(*) FROM orders) AS order_count;

-- =========================================================
-- 2. REVENUE PER CUSTOMER (STABLE GROUPING)
-- =========================================================
SELECT
    c.customer_id,
    MAX(c.legal_name) AS legal_name,
    SUM(o.total_amount) AS total_revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_revenue DESC;

-- =========================================================
-- 3. HIGH-VALUE CUSTOMERS (TOP 25%) 
-- =========================================================
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        MAX(c.legal_name) AS legal_name,
        SUM(o.total_amount) AS total_revenue
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rn,
        COUNT(*) OVER () AS total_count
    FROM customer_revenue
)
SELECT
    customer_id,
    legal_name,
    total_revenue
FROM ranked
WHERE rn <= CEIL(0.25 * total_count)
ORDER BY total_revenue DESC;


-- =========================================================
-- 4. ORDER STATISTICS
-- =========================================================
SELECT
    AVG(total_amount) AS avg_order_value,
    MIN(total_amount) AS min_order_value,
    MAX(total_amount) AS max_order_value,
    STDDEV_POP(total_amount) AS stddev_order_value,
    VAR_POP(total_amount) AS variance_order_value
FROM orders;

-- =========================================================
-- 5. REVENUE BY STATUS
-- =========================================================
SELECT
    order_status,
    SUM(total_amount) AS revenue,
    ROUND(
        SUM(total_amount) * 100.0 /
        SUM(SUM(total_amount)) OVER (),
        2
    ) AS revenue_pct
FROM orders
GROUP BY order_status
ORDER BY revenue DESC;

-- =========================================================
-- 6. PAYMENTS ROLLUP 
-- =========================================================
SELECT
    YEAR(payment_date) AS yr,
    MONTH(payment_date) AS mo,
    IFNULL(payment_status, 'TOTAL') AS payment_status,
    COUNT(*) AS payment_count,
    SUM(amount) AS payment_amount
FROM payments
GROUP BY YEAR(payment_date), MONTH(payment_date), payment_status WITH ROLLUP;

-- =========================================================
-- 7. CATEGORY REVENUE
-- =========================================================
SELECT
    pc.category_name,
    COUNT(*) AS order_lines,
    SUM((oi.unit_price - oi.discount_amount) * oi.quantity) AS line_revenue
FROM product_categories pc
JOIN products p ON p.category_id = pc.category_id
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY pc.category_name
ORDER BY line_revenue DESC;


-- =========================================================
-- 8. ADVISOR LOAD
-- =========================================================
SELECT
    ad.region,
    ad.tier,
    COUNT(DISTINCT aa.account_id) AS assigned_accounts
FROM advisors ad
LEFT JOIN account_advisors aa ON aa.advisor_id = ad.advisor_id
GROUP BY ad.region, ad.tier
ORDER BY assigned_accounts DESC;

-- =========================================================
-- 9. KPI SNAPSHOT 
-- =========================================================
SELECT
    (SELECT COUNT(*) FROM customers WHERE status = 'active') AS active_customers,
    (SELECT COUNT(*) FROM accounts WHERE status = 'open') AS open_accounts,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE order_status = 'fulfilled') AS fulfilled_revenue,
    (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payment_status = 'settled') AS settled_cash,
    (SELECT AVG(total_amount) FROM orders) AS avg_order_value;
/* =========================================================
   SCRIPT 6: CTES & RECURSIVE SQL
   Purpose: Multi-step transformations, hierarchies, and recursion.
   ========================================================= */

USE northstar_finance;

-- 1. Customer Lifetime Value
WITH order_base AS (
    SELECT
        o.order_id,
        o.order_number,
        o.customer_id,
        o.total_amount,
        o.order_date
    FROM orders o
    WHERE o.order_status IN ('confirmed', 'fulfilled')
),
customer_totals AS (
    SELECT
        customer_id,
        SUM(total_amount) AS lifetime_value
    FROM order_base
    GROUP BY customer_id
)
SELECT
    c.legal_name,
    ct.lifetime_value
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY ct.lifetime_value DESC;

-- 2. Monthly Revenue
WITH order_lines AS (
    SELECT
        o.order_date,
        oi.quantity * oi.unit_price - oi.discount_amount AS net_line_amount
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('confirmed', 'fulfilled')   -- FIXED
),
monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS revenue_month,
        SUM(net_line_amount) AS revenue
    FROM order_lines
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT *
FROM monthly_revenue
ORDER BY revenue_month;

-- 3. Recursive Months
WITH RECURSIVE months AS (
    SELECT 1 AS month_num
    UNION ALL
    SELECT month_num + 1
    FROM months
    WHERE month_num < 12
)
SELECT month_num
FROM months;

-- 4. Org Hierarchy
WITH RECURSIVE org_tree AS (
    SELECT
        employee_id,
        full_name,
        job_title,
        manager_id,
        0 AS level,
        CAST(full_name AS CHAR(500)) AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id,
        e.full_name,
        e.job_title,
        e.manager_id,
        ot.level + 1,
        CONCAT(ot.path, ' -> ', e.full_name)
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.employee_id
    WHERE ot.level < 10   -- FIXED: prevents infinite loops
)
SELECT *
FROM org_tree
ORDER BY path;
 
-- 5. Missing Invoice Numbers
WITH RECURSIVE seq AS (
    SELECT 10001 AS n
    UNION ALL
    SELECT n + 1
    FROM seq
    WHERE n < 10010
)
SELECT s.n AS missing_invoice_number
FROM seq s
LEFT JOIN orders o 
    ON o.order_number = CONCAT('ORD-', s.n)   -- FIXED (was INV-)
WHERE o.order_number IS NULL;
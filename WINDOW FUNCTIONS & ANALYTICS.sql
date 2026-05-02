/* =========================================================
WINDOW FUNCTIONS & ANALYTICS
Purpose: Business-focused ranking, sequencing, and trends
========================================================= */

USE northstar_finance;

/* ---------------------------------------------------------

1. Order Value Ranking
   Business Use: Identify highest revenue orders
   --------------------------------------------------------- */
   SELECT
   o.order_number,
   o.customer_id,
   o.total_amount,
   ROW_NUMBER() OVER (ORDER BY o.total_amount DESC, o.order_id) AS row_num,
   RANK() OVER (ORDER BY o.total_amount DESC) AS value_rank,
   DENSE_RANK() OVER (ORDER BY o.total_amount DESC) AS dense_value_rank
   FROM orders o;

/* ---------------------------------------------------------
2. Top Orders Per Customer
Business Use: Find each customer’s highest-value orders
--------------------------------------------------------- */
SELECT
o.customer_id,
o.order_number,
o.total_amount,
ROW_NUMBER() OVER (
PARTITION BY o.customer_id
ORDER BY o.total_amount DESC, o.order_id
) AS customer_rank
FROM orders o;

/* ---------------------------------------------------------
3. Customer Running Revenue
Business Use: Track revenue growth per customer over time
--------------------------------------------------------- */
SELECT
o.customer_id,
o.order_date,
o.order_number,
o.total_amount,
SUM(o.total_amount) OVER (
PARTITION BY o.customer_id
ORDER BY o.order_date, o.order_id
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS customer_running_revenue
FROM orders o
ORDER BY o.customer_id, o.order_date, o.order_id;

/* ---------------------------------------------------------
4. Moving Average (3 Orders)
Business Use: Smooth short-term revenue fluctuations
--------------------------------------------------------- */
SELECT
o.order_date,
o.order_number,
o.total_amount,
AVG(o.total_amount) OVER (
ORDER BY o.order_date, o.order_id
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
) AS moving_avg_3_orders
FROM orders o
ORDER BY o.order_date, o.order_id;

/* ---------------------------------------------------------
5. Payment Trend Over Time
Business Use: Detect spikes or drops in payments
--------------------------------------------------------- */
SELECT
p.payment_reference,
p.payment_date,
p.amount,
LAG(p.amount) OVER (ORDER BY p.payment_date) AS previous_amount,
(p.amount - LAG(p.amount) OVER (ORDER BY p.payment_date)) AS change_amount
FROM payments p;

/* ---------------------------------------------------------
6. Customer Payment Sequencing
Business Use: Understand payment behavior per customer
--------------------------------------------------------- */
SELECT
c.customer_id,
p.payment_date,
p.amount,
ROW_NUMBER() OVER (
PARTITION BY c.customer_id
ORDER BY p.payment_date
) AS payment_sequence
FROM payments p
JOIN orders o ON p.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id;

/* ---------------------------------------------------------
7. Revenue Distribution (Percentiles)
Business Use: Position orders within overall distribution
--------------------------------------------------------- */
SELECT
o.order_number,
o.total_amount,
PERCENT_RANK() OVER (ORDER BY o.total_amount DESC) AS pct_rank_desc,
CUME_DIST() OVER (ORDER BY o.total_amount DESC) AS cumulative_dist_desc
FROM orders o;

/* ---------------------------------------------------------
8. First and Last Customer Orders
Business Use: Customer lifecycle analysis
--------------------------------------------------------- */
SELECT
o.customer_id,
o.order_number,
o.order_date,
FIRST_VALUE(o.order_number) OVER (
PARTITION BY o.customer_id
ORDER BY o.order_date, o.order_id
) AS first_order,
LAST_VALUE(o.order_number) OVER (
PARTITION BY o.customer_id
ORDER BY o.order_date, o.order_id
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
) AS last_order
FROM orders o;

/* ---------------------------------------------------------
9. Account Balance Distribution
Business Use: Understand relative balance positioning
--------------------------------------------------------- */
SELECT
a.account_number,
a.balance,
PERCENT_RANK() OVER (ORDER BY a.balance DESC) AS balance_percentile
FROM accounts a;
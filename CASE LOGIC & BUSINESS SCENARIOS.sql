/* =========================================================
   SCRIPT 8: CASE LOGIC & BUSINESS SCENARIOS
   ========================================================= */

USE northstar_finance;

/* ---------------------------
   1. Order segmentation
   --------------------------- */
SELECT
    o.order_number,
    o.total_amount,
    CASE
        WHEN o.total_amount >= 400 THEN 'enterprise'
        WHEN o.total_amount >= 200 THEN 'growth'
        WHEN o.total_amount >= 100 THEN 'standard'
        ELSE 'small'
    END AS order_segment
FROM orders o;

/* ---------------------------
   2. Customer risk scoring (NULL-safe)
   --------------------------- */
SELECT
    c.customer_id,
    c.legal_name,
    COALESCE(cp.risk_band, 'medium') AS risk_band,
    (
        CASE
            WHEN cp.risk_band = 'high' THEN 80
            WHEN cp.risk_band = 'medium' THEN 50
            ELSE 20
        END
        + CASE WHEN c.status = 'paused' THEN 15 ELSE 0 END
        + CASE WHEN cp.kyc_verified_flag = 0 OR cp.kyc_verified_flag IS NULL THEN 10 ELSE 0 END
    ) AS risk_score
FROM customers c
LEFT JOIN customer_profiles cp ON cp.customer_id = c.customer_id;

/* ---------------------------
   3. Customer lifetime value segmentation
   --------------------------- */
SELECT
    c.customer_id,
    c.legal_name,
    SUM(o.total_amount) AS lifetime_value,
    CASE
        WHEN SUM(o.total_amount) >= 500 THEN 'platinum'
        WHEN SUM(o.total_amount) >= 200 THEN 'gold'
        WHEN SUM(o.total_amount) >= 100 THEN 'silver'
        ELSE 'bronze'
    END AS segment
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.legal_name;

/* ---------------------------
   4. Advisor classification
   --------------------------- */
SELECT
    ad.full_name,
    ad.tier,
    CASE
        WHEN ad.tier = 'principal' THEN 'strategic'
        WHEN ad.tier = 'senior' THEN 'commercial'
        ELSE 'entry'
    END AS advisory_class
FROM advisors ad;

/* ---------------------------
   5. Order next action (optimized)
   --------------------------- */
SELECT
    o.order_number,
    o.order_status,
    o.total_amount,
    CASE
        WHEN o.order_status = 'draft' AND o.total_amount > 100 THEN 'opportunity'
        WHEN o.order_status = 'confirmed' AND p.pending_flag = 1 THEN 'payment follow-up'
        ELSE 'normal'
    END AS next_action
FROM orders o
LEFT JOIN (
    SELECT
        order_id,
        MAX(CASE WHEN payment_status = 'pending' THEN 1 ELSE 0 END) AS pending_flag
    FROM payments
    GROUP BY order_id
) p ON p.order_id = o.order_id;

/* ---------------------------
   6. Order summary metrics
   --------------------------- */
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'fulfilled' THEN 1 ELSE 0 END) AS fulfilled_orders,
    SUM(CASE WHEN order_status = 'draft' THEN 1 ELSE 0 END) AS draft_orders,
    SUM(CASE WHEN order_status = 'fulfilled' THEN total_amount ELSE 0 END) AS fulfilled_revenue
FROM orders;

/* ---------------------------
   7. Data quality checks (optimized)
   --------------------------- */
SELECT
    o.order_number,
    CASE
        WHEN o.subtotal < 0 OR o.total_amount < 0 THEN 'invalid_amount'
        WHEN o.total_amount < o.subtotal THEN 'discount_or_adjustment'
        WHEN o.order_status = 'fulfilled' AND p.settled_flag = 0 THEN 'missing_settled_payment'
        ELSE 'ok'
    END AS data_quality_flag
FROM orders o
LEFT JOIN (
    SELECT
        order_id,
        MAX(CASE WHEN payment_status = 'settled' THEN 1 ELSE 0 END) AS settled_flag
    FROM payments
    GROUP BY order_id
) p ON p.order_id = o.order_id;

/* ---------------------------
   8. Monthly revenue dashboard
   --------------------------- */
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
    SUM(o.total_amount) AS revenue,
    COUNT(*) AS orders_count,
    SUM(CASE WHEN o.order_status = 'fulfilled' THEN 1 ELSE 0 END) AS fulfilled_count
FROM orders o
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY sales_month;
/* =========================================================
   SCRIPT 4: JOINS MASTERY
   Purpose: Explore join types on one consistent dataset.
   ========================================================= */

USE northstar_finance;

/* 1. INNER JOIN ACROSS CUSTOMER → ACCOUNT → ORDER */
SELECT
    c.legal_name,
    a.account_number,
    o.order_number,
    o.total_amount,
    o.order_date
FROM customers c
INNER JOIN accounts a ON a.customer_id = c.customer_id
INNER JOIN orders o ON o.account_id = a.account_id
ORDER BY c.legal_name, o.order_date;


/* 2. CUSTOMERS WITH NO ORDERS (ANTI-JOIN) */
SELECT
    c.customer_id,
    c.legal_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;


/* 3. ACCOUNTS WITH NO ADVISORS */
SELECT
    a.account_number,
    a.account_type
FROM accounts a
LEFT JOIN account_advisors aa ON aa.account_id = a.account_id
WHERE aa.advisor_id IS NULL;



/* 4. ADVISORS WITH NO ACCOUNTS */
SELECT
    ad.advisor_code,
    ad.full_name
FROM advisors ad
LEFT JOIN account_advisors aa ON aa.advisor_id = ad.advisor_id
WHERE aa.account_id IS NULL;

/* 5. CROSS JOIN (WARNING: CARTESIAN PRODUCT - FOR ANALYSIS ONLY) */
SELECT
    c.legal_name,
    ad.region
FROM customers c
CROSS JOIN advisors ad
ORDER BY c.customer_id, ad.region;

/* 6. EMPLOYEE HIERARCHY (SELF JOIN FIXED ORDERING) */
SELECT
    e.employee_code,
    e.full_name AS employee_name,
    e.job_title,
    m.full_name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY e.manager_id, e.full_name;

/* 7. FULL OUTER JOIN EMULATION (CLEANED - NO DUPLICATION BUG) */
SELECT
    c.customer_id,
    c.legal_name,
    o.order_id,
    o.order_number
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id

UNION ALL

SELECT
    c.customer_id,
    c.legal_name,
    o.order_id,
    o.order_number
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

/* 8. DATA INTEGRITY CHECKS */
SELECT
    'orders without matching customers' AS issue_type,
    o.order_number AS record_key
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'payments without matching orders' AS issue_type,
    p.payment_reference AS record_key
FROM payments p
LEFT JOIN orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL;

/* 9. CUSTOMER → PROFILE → ACCOUNT → ADVISOR CHAIN */
SELECT
    c.customer_code,
    c.legal_name,
    cp.risk_band,
    cp.kyc_verified_flag,
    a.account_number,
    ad.full_name AS advisor_name
FROM customers c
LEFT JOIN customer_profiles cp ON cp.customer_id = c.customer_id
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN account_advisors aa 
    ON aa.account_id = a.account_id 
   AND aa.assignment_role = 'primary'
LEFT JOIN advisors ad ON ad.advisor_id = aa.advisor_id
ORDER BY c.legal_name, a.account_number;
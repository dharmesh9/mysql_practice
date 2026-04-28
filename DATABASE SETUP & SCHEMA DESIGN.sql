/* =========================================================
   SCRIPT 1: DATABASE SETUP & SCHEMA DESIGN
   Business domain: Northstar Financial Commerce
   Purpose: Create the base schema, relationships, and seed data.
   ========================================================= */

DROP DATABASE IF EXISTS northstar_finance;
CREATE DATABASE northstar_finance;
USE northstar_finance;

/* ---------------------------
   Core reference tables
   --------------------------- */

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_code VARCHAR(20) NOT NULL UNIQUE,
    legal_name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    status ENUM('prospect', 'active', 'paused', 'closed') NOT NULL DEFAULT 'prospect',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (email LIKE '%@%')
) ENGINE=InnoDB;

CREATE TABLE advisors (
    advisor_id INT AUTO_INCREMENT PRIMARY KEY,
    advisor_code VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    region VARCHAR(50) NOT NULL,
    tier ENUM('associate', 'senior', 'principal') NOT NULL DEFAULT 'associate',
    hire_date DATE NOT NULL,
    active_flag TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (email LIKE '%@%')
) ENGINE=InnoDB;

/* One-to-one: each customer can have one profile row */
CREATE TABLE customer_profiles (
    customer_id INT PRIMARY KEY,
    date_of_birth DATE,
    annual_revenue DECIMAL(12,2),
    risk_band ENUM('low', 'medium', 'high') DEFAULT 'medium',
    kyc_verified_flag TINYINT(1) NOT NULL DEFAULT 0,
    notes VARCHAR(500),
    CONSTRAINT fk_customer_profiles_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* One-to-many: one customer can own many accounts */
CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    account_number VARCHAR(30) NOT NULL UNIQUE,
    account_type ENUM('checking', 'savings', 'investment', 'merchant') NOT NULL,
    open_date DATE NOT NULL,
    status ENUM('open', 'suspended', 'closed') NOT NULL DEFAULT 'open',
    balance DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    credit_limit DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    CHECK (balance >= 0),
    CHECK (credit_limit >= 0),
    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* One advisor can manage many accounts */
CREATE TABLE account_advisors (
    account_id INT NOT NULL,
    advisor_id INT NOT NULL,
    assigned_at DATE NOT NULL,
    assignment_role ENUM('primary', 'secondary') NOT NULL DEFAULT 'primary',
    PRIMARY KEY (account_id, advisor_id),
    CONSTRAINT fk_account_advisors_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_account_advisors_advisor
        FOREIGN KEY (advisor_id) REFERENCES advisors(advisor_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* Product catalog */
CREATE TABLE product_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_sku VARCHAR(30) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    active_flag TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (unit_price > 0),
    CHECK (cost_price >= 0),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES product_categories(category_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* Many-to-many: products can have multiple features */
CREATE TABLE product_features (
    feature_id INT AUTO_INCREMENT PRIMARY KEY,
    feature_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE product_feature_map (
    product_id INT NOT NULL,
    feature_id INT NOT NULL,
    PRIMARY KEY (product_id, feature_id),
    CONSTRAINT fk_pfm_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pfm_feature
        FOREIGN KEY (feature_id) REFERENCES product_features(feature_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

/* Business transactions */
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    account_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status ENUM('draft', 'confirmed', 'fulfilled', 'cancelled') NOT NULL DEFAULT 'draft',
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CHECK (subtotal >= 0),
    CHECK (tax_amount >= 0),
    CHECK (total_amount >= 0),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    CHECK (discount_amount >= 0),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_reference VARCHAR(40) NOT NULL UNIQUE,
    payment_date DATE NOT NULL,
    payment_method ENUM('card', 'bank_transfer', 'direct_debit', 'wallet') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_status ENUM('pending', 'settled', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    CHECK (amount > 0),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    transaction_date DATETIME NOT NULL,
    transaction_type ENUM('debit', 'credit', 'fee', 'refund') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    reference_code VARCHAR(40) NOT NULL,
    narration VARCHAR(255),
    CHECK (amount > 0),
    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* Self-reference: employee manager hierarchy */
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    manager_id INT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(12,2) NOT NULL,
    active_flag TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (salary >= 0),
    CONSTRAINT fk_employees_manager
        FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

/* ---------------------------
   Seed sample data
   --------------------------- */

INSERT INTO customers (customer_code, legal_name, contact_name, email, phone, status)
VALUES
('CUST-1001', 'Apex Retail Group Ltd', 'Maya Patel', 'maya.patel@apexretail.com', '+44 20 7000 1001', 'active'),
('CUST-1002', 'Brightline Logistics Plc', 'Daniel Reed', 'daniel.reed@brightline.co.uk', '+44 20 7000 1002', 'active'),
('CUST-1003', 'Cedar Health Services Ltd', 'Priya Singh', 'priya.singh@cedarhealth.co.uk', '+44 20 7000 1003', 'active'),
('CUST-1004', 'Delta Manufacturing Ltd', 'Oliver Shaw', 'oliver.shaw@deltamfg.co.uk', '+44 20 7000 1004', 'paused'),
('CUST-1005', 'Evergreen Advisory Partners', 'Hannah Cole', 'hannah.cole@evergreenadvisory.com', '+44 20 7000 1005', 'active');

INSERT INTO customer_profiles (customer_id, date_of_birth, annual_revenue, risk_band, kyc_verified_flag, notes)
VALUES
(1, '1984-06-14', 1250000.00, 'medium', 1, 'Multi-site retailer'),
(2, '1979-11-02', 3100000.00, 'low', 1, 'Uses multiple shipping lanes'),
(3, '1988-03-22', 890000.00, 'medium', 1, 'Healthcare services provider'),
(4, '1975-09-09', 5400000.00, 'high', 0, 'Manual review pending'),
(5, '1991-01-18', 760000.00, 'low', 1, 'Professional services client');

INSERT INTO advisors (advisor_code, full_name, email, region, tier, hire_date)
VALUES
('ADV-001', 'Sofia Morgan', 'sofia.morgan@northstar.com', 'London', 'principal', '2017-04-10'),
('ADV-002', 'James Turner', 'james.turner@northstar.com', 'South East', 'senior', '2019-08-19'),
('ADV-003', 'Lily Chen', 'lily.chen@northstar.com', 'Midlands', 'associate', '2022-02-14'),
('ADV-004', 'Noah Williams', 'noah.williams@northstar.com', 'North', 'senior', '2018-12-03');

INSERT INTO accounts (customer_id, account_number, account_type, open_date, status, balance, credit_limit)
VALUES
(1, 'ACC-90001', 'merchant', '2022-01-15', 'open', 25000.00, 50000.00),
(2, 'ACC-90002', 'merchant', '2021-05-21', 'open', 18000.00, 40000.00),
(3, 'ACC-90003', 'checking', '2023-02-10', 'open', 1200.00, 5000.00),
(4, 'ACC-90004', 'investment', '2020-11-01', 'suspended', 85000.00, 20000.00),
(5, 'ACC-90005', 'savings', '2024-01-05', 'open', 4300.00, 10000.00),
(1, 'ACC-90006', 'checking', '2024-06-11', 'open', 3200.00, 15000.00);

INSERT INTO account_advisors (account_id, advisor_id, assigned_at, assignment_role)
VALUES
(1, 1, '2022-01-15', 'primary'),
(2, 2, '2021-05-21', 'primary'),
(3, 3, '2023-02-10', 'primary'),
(4, 4, '2020-11-01', 'primary'),
(5, 1, '2024-01-05', 'secondary'),
(6, 2, '2024-06-11', 'primary');

INSERT INTO product_categories (category_name, is_active)
VALUES
('Payments', 1),
('Cash Management', 1),
('Lending', 1),
('Analytics', 1);

INSERT INTO products (product_sku, product_name, category_id, unit_price, cost_price, active_flag)
VALUES
('PROD-PAY-01', 'Card Processing Plus', 1, 49.00, 12.00, 1),
('PROD-CASH-01', 'Daily Sweep Service', 2, 29.00, 8.00, 1),
('PROD-LEND-01', 'Working Capital Line', 3, 199.00, 70.00, 1),
('PROD-ANLY-01', 'Revenue Insight Dashboard', 4, 89.00, 22.00, 1);

INSERT INTO product_features (feature_name)
VALUES
('Recurring Billing'),
('Fraud Alerts'),
('API Access'),
('Custom Reporting'),
('Priority Support');

INSERT INTO product_feature_map (product_id, feature_id)
VALUES
(1, 1), (1, 2), (1, 3),
(2, 3), (2, 5),
(3, 2), (3, 5),
(4, 3), (4, 4), (4, 5);

INSERT INTO orders (order_number, customer_id, account_id, order_date, order_status, subtotal, tax_amount, total_amount)
VALUES
('ORD-10001', 1, 1, '2025-01-10', 'fulfilled', 147.00, 29.40, 176.40),
('ORD-10002', 2, 2, '2025-01-14', 'fulfilled', 228.00, 45.60, 273.60),
('ORD-10003', 3, 3, '2025-02-02', 'confirmed', 89.00, 17.80, 106.80),
('ORD-10004', 1, 6, '2025-02-18', 'draft', 98.00, 19.60, 117.60),
('ORD-10005', 5, 5, '2025-03-01', 'fulfilled', 356.00, 71.20, 427.20);

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_amount)
VALUES
(1, 1, 2, 49.00, 0.00),
(1, 2, 1, 29.00, 0.00),
(2, 1, 3, 49.00, 0.00),
(2, 4, 1, 81.00, 0.00),
(3, 4, 1, 89.00, 0.00),
(4, 1, 1, 49.00, 0.00),
(4, 2, 1, 29.00, 0.00),
(5, 3, 1, 199.00, 0.00),
(5, 4, 1, 89.00, 0.00),
(5, 1, 1, 49.00, 0.00);

INSERT INTO payments (order_id, payment_reference, payment_date, payment_method, amount, payment_status)
VALUES
(1, 'PAY-50001', '2025-01-11', 'card', 176.40, 'settled'),
(2, 'PAY-50002', '2025-01-15', 'bank_transfer', 273.60, 'settled'),
(3, 'PAY-50003', '2025-02-03', 'direct_debit', 106.80, 'pending'),
(5, 'PAY-50005', '2025-03-02', 'card', 427.20, 'settled');

INSERT INTO transactions (account_id, transaction_date, transaction_type, amount, reference_code, narration)
VALUES
(1, '2025-01-11 09:00:00', 'debit', 176.40, 'PAY-50001', 'Order settlement'),
(2, '2025-01-15 10:30:00', 'debit', 273.60, 'PAY-50002', 'Order settlement'),
(3, '2025-02-03 14:10:00', 'debit', 106.80, 'PAY-50003', 'Pending settlement'),
(5, '2025-03-02 08:45:00', 'debit', 427.20, 'PAY-50005', 'Order settlement'),
(1, '2025-03-05 16:20:00', 'credit', 2500.00, 'DEP-70001', 'Top-up deposit');

INSERT INTO employees (employee_code, full_name, job_title, manager_id, hire_date, salary)
VALUES
('EMP-001', 'Grace Hall', 'Chief Revenue Officer', NULL, '2016-07-01', 165000.00),
('EMP-002', 'Ethan Brooks', 'Sales Director', 1, '2018-02-12', 112000.00),
('EMP-003', 'Chloe Evans', 'Finance Manager', 1, '2019-10-08', 98000.00),
('EMP-004', 'Jack Wilson', 'CRM Analyst', 2, '2021-04-19', 68000.00),
('EMP-005', 'Ava Green', 'Accounts Specialist', 3, '2022-09-05', 54000.00);
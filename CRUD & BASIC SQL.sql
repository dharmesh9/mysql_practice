/* =========================================================
   SCRIPT 2: CRUD & BASIC SQL
   Purpose: Practice row-level operations and core filtering.
   Standalone demo table included.
   ========================================================= */

USE northstar_finance;

DROP TABLE IF EXISTS demo_leads;
CREATE TABLE demo_leads (
    lead_id INT AUTO_INCREMENT PRIMARY KEY,
    lead_name VARCHAR(150) NOT NULL,
    email VARCHAR(255),
    source VARCHAR(50) NOT NULL,
    lead_status ENUM('new', 'contacted', 'qualified', 'lost') NOT NULL DEFAULT 'new',
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    owner_name VARCHAR(150) NULL
);

INSERT INTO demo_leads (lead_name, email, source, lead_status, created_at, owner_name)
VALUES
('Metro Foods Ltd', 'ops@metrofoods.co.uk', 'web', 'new', '2025-03-01', 'Sales Queue'),
('North Bay Trading', 'finance@northbay.com', 'referral', 'qualified', '2025-03-02', 'Sofia Morgan'),
('Summit Health Group', NULL, 'event', 'contacted', '2025-03-03', NULL),
('Urban Edge Retail', 'hello@urbanedge.com', 'web', 'lost', '2025-03-04', 'Sales Queue'),
('Vista Freight', 'contact@vistafreight.co.uk', 'email', 'new', '2025-03-05', NULL);

/* Business question: Which leads are still active? */
SELECT lead_id, lead_name, email, source, lead_status
FROM demo_leads
WHERE lead_status IN ('new', 'contacted', 'qualified')
ORDER BY created_at DESC
LIMIT 10;

/* Business question: Which sources are represented? */
SELECT DISTINCT source
FROM demo_leads
ORDER BY source;

/* Business question: Which web leads lack an email address? */
SELECT *
FROM demo_leads
WHERE source = 'web'
  AND email IS NULL;

/* Business question: Which leads are from partner-like channels? */
SELECT *
FROM demo_leads
WHERE source IN ('referral', 'email');

/* Business question: Which records are not lost? */
SELECT *
FROM demo_leads
WHERE NOT lead_status = 'lost';

/* Business question: Which leads were created in the first five days of March 2025? */
SELECT *
FROM demo_leads
WHERE created_at BETWEEN '2025-03-01' AND '2025-03-05'
ORDER BY created_at;

/* Business question: Which lead names contain Group? */
SELECT *
FROM demo_leads
WHERE lead_name LIKE '%Group%';

/* Business question: Which records still need owner assignment? */
SELECT *
FROM demo_leads
WHERE owner_name IS NULL;

SET SQL_SAFE_UPDATES = 0;
/* CRUD examples */
UPDATE demo_leads
SET lead_status = 'contacted'
WHERE lead_name = 'Metro Foods Ltd';

UPDATE demo_leads
SET source = 'partner'
WHERE source = 'referral';

DELETE FROM demo_leads
WHERE lead_status = 'lost';

/* Schema change example */
ALTER TABLE demo_leads
ADD COLUMN lead_score INT NULL;

UPDATE demo_leads
SET lead_score = 80
WHERE lead_name = 'Metro Foods Ltd';

TRUNCATE TABLE demo_leads;

INSERT INTO demo_leads (
    lead_name,
    email,
    source,
    lead_status,
    created_at,
    owner_name,
    lead_score
)
VALUES
    ('Metro Foods Ltd', 'ops@metrofoods.co.uk', 'web', 'new', '2025-03-01', 'Sales Queue', 80),
    ('North Bay Trading', 'finance@northbay.com', 'partner', 'qualified', '2025-03-02', 'Sofia Morgan', 92);

SELECT * 
FROM demo_leads;
-- SQL Patterns Cookbook
-- ====================
-- Intermediate to advanced SQL patterns commonly asked in data engineering
-- and forward deployed engineer interviews.
-- All queries are written for SQLite (portable, no external DB needed).

-- Setup: Create sample schema
CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT PRIMARY KEY,
    name TEXT,
    region TEXT,
    signup_date TEXT
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id TEXT PRIMARY KEY,
    customer_id TEXT,
    account_type TEXT,
    balance REAL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id TEXT PRIMARY KEY,
    account_id TEXT,
    amount REAL,
    transaction_date TEXT,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Insert sample data
INSERT INTO customers VALUES 
    ('CUST001', 'Alice', 'APAC', '2020-01-15'),
    ('CUST002', 'Bob', 'EMEA', '2021-03-20'),
    ('CUST003', 'Charlie', 'AMER', '2022-06-10'),
    ('CUST004', 'Diana', 'APAC', '2021-11-05');

INSERT INTO accounts VALUES 
    ('ACC001', 'CUST001', 'checking', 1000.00),
    ('ACC002', 'CUST001', 'savings', 2500.00),
    ('ACC003', 'CUST002', 'checking', 500.00),
    ('ACC004', 'CUST003', 'credit', 3000.00),
    ('ACC005', 'CUST004', 'savings', 750.00);

INSERT INTO transactions VALUES 
    ('TXN001', 'ACC001', 100.00, '2026-01-01'),
    ('TXN002', 'ACC001', 250.00, '2026-01-05'),
    ('TXN003', 'ACC002', 500.00, '2026-01-10'),
    ('TXN004', 'ACC003', 75.00, '2026-01-15'),
    ('TXN005', 'ACC004', 1200.00, '2026-01-20'),
    ('TXN006', 'ACC001', 150.00, '2026-02-01'),
    ('TXN007', 'ACC005', 300.00, '2026-02-05');

-- =========================================================================
-- PATTERN 1: Window Functions (ROW_NUMBER, RANK, Dense_RANK, LAG, LEAD)
-- =========================================================================

-- Find the most recent transaction per account
SELECT 
    account_id,
    transaction_id,
    amount,
    transaction_date,
    ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY transaction_date DESC) as recency_rank
FROM transactions
WHERE ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY transaction_date DESC) = 1;

-- Running total of transaction amounts per account
SELECT 
    account_id,
    transaction_id,
    amount,
    SUM(amount) OVER (PARTITION BY account_id ORDER BY transaction_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM transactions;

-- Difference between consecutive transactions in an account
SELECT 
    account_id,
    transaction_id,
    amount,
    LAG(amount) OVER (PARTITION BY account_id ORDER BY transaction_date) as prev_amount,
    amount - LAG(amount) OVER (PARTITION BY account_id ORDER BY transaction_date) as amount_change
FROM transactions;

-- =========================================================================
-- PATTERN 2: Common Table Expressions (CTEs) / WITH clauses
-- =========================================================================

-- CTE for high-value customers (total balance > 2000), then join with their transaction count
WITH customer_balances AS (
    SELECT 
        c.customer_id,
        c.name,
        SUM(a.balance) as total_balance
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    GROUP BY c.customer_id, c.name
    HAVING SUM(a.balance) > 2000
),
transaction_counts AS (
    SELECT 
        a.customer_id,
        COUNT(*) as txn_count
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    GROUP BY a.customer_id
)
SELECT 
    cb.customer_id,
    cb.name,
    cb.total_balance,
    COALESCE(tc.txn_count, 0) as txn_count
FROM customer_balances cb
LEFT JOIN transaction_counts tc ON cb.customer_id = tc.customer_id;

-- =========================================================================
-- PATTERN 3: Aggregation with HAVING (filter on aggregated values)
-- =========================================================================

-- Find customers with more than one account
SELECT 
    c.customer_id,
    c.name,
    COUNT(a.account_id) as num_accounts,
    SUM(a.balance) as total_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(a.account_id) > 1;

-- Find accounts with transaction volume above the median
SELECT 
    account_id,
    COUNT(*) as txn_count,
    SUM(amount) as total_amount
FROM transactions
GROUP BY account_id
HAVING COUNT(*) > (SELECT COUNT(*) / 2.0 FROM transactions);

-- =========================================================================
-- PATTERN 4: Subqueries (scalar and correlated)
-- =========================================================================

-- Scalar subquery: get total transaction volume per account
SELECT 
    a.account_id,
    a.account_type,
    a.balance,
    (SELECT COUNT(*) FROM transactions t WHERE t.account_id = a.account_id) as txn_count,
    (SELECT SUM(amount) FROM transactions t WHERE t.account_id = a.account_id) as txn_sum
FROM accounts a;

-- NOT IN subquery: customers who have no transactions
SELECT 
    customer_id,
    name
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT a.customer_id 
    FROM accounts a 
    WHERE a.account_id IN (SELECT account_id FROM transactions)
);

-- =========================================================================
-- PATTERN 5: UNION / UNION ALL (combine result sets)
-- =========================================================================

-- Combine high-balance accounts with high-volume accounts
SELECT 
    account_id,
    'High Balance' as category
FROM accounts
WHERE balance > 2000

UNION

SELECT 
    account_id,
    'High Volume' as category
FROM (
    SELECT account_id, COUNT(*) as txn_count
    FROM transactions
    GROUP BY account_id
    HAVING COUNT(*) > 3
);

-- =========================================================================
-- PATTERN 6: Self-join (compare a table to itself)
-- =========================================================================

-- Find customers in the same region
SELECT 
    c1.customer_id as customer_1,
    c1.name as name_1,
    c2.customer_id as customer_2,
    c2.name as name_2,
    c1.region
FROM customers c1
JOIN customers c2 ON c1.region = c2.region AND c1.customer_id < c2.customer_id;

-- =========================================================================
-- PATTERN 7: CASE statements (conditional logic in SQL)
-- =========================================================================

-- Categorize accounts by balance tier
SELECT 
    account_id,
    balance,
    CASE 
        WHEN balance > 2000 THEN 'High Value'
        WHEN balance > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END as balance_tier,
    CASE 
        WHEN account_type = 'credit' THEN 'Risk'
        ELSE 'Secure'
    END as risk_category
FROM accounts;

-- =========================================================================
-- PATTERN 8: Date filtering (BETWEEN, date functions)
-- =========================================================================

-- Transactions in January 2026
SELECT 
    transaction_id,
    amount,
    transaction_date
FROM transactions
WHERE transaction_date BETWEEN '2026-01-01' AND '2026-01-31';

-- Customers who signed up in the last 2 years
SELECT 
    customer_id,
    name,
    signup_date
FROM customers
WHERE signup_date >= date('now', '-2 years');

-- =========================================================================
-- PATTERN 9: GROUP BY with multiple aggregations
-- =========================================================================

-- Summary by customer and region
SELECT 
    c.customer_id,
    c.name,
    c.region,
    COUNT(DISTINCT a.account_id) as num_accounts,
    SUM(a.balance) as total_balance,
    COUNT(t.transaction_id) as num_transactions,
    SUM(t.amount) as total_txn_volume,
    AVG(t.amount) as avg_txn_amount
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.name, c.region;

-- =========================================================================
-- PATTERN 10: Recursive CTE (hierarchical data - simplified example)
-- =========================================================================

-- Generate a sequence of numbers (common in generating test data)
WITH RECURSIVE number_sequence AS (
    SELECT 1 as num
    UNION ALL
    SELECT num + 1 FROM number_sequence WHERE num < 5
)
SELECT num FROM number_sequence;

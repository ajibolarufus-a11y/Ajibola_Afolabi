-- Portfolio 2: Query Processing and Optimisation (NovaBank)

-- 1. SEED DATA (run once only)
INSERT INTO customers (full_name, email)
SELECT 'Customer '||g, 'user'||g||'@mail.com' FROM generate_series(1,10000) g;

INSERT INTO accounts (customer_id, acct_number, balance)
SELECT customer_id, lpad(customer_id::text,10,'0'), (random()*500000)::numeric(14,2)
FROM customers;

WITH ids AS (SELECT array_agg(account_id) AS a FROM accounts)
INSERT INTO transactions (account_id, txn_type, amount, created_at)
SELECT a[1 + floor(random()*array_length(a,1))::int],
       'deposit',
       (random()*50000+1)::numeric(14,2),
       now() - (random()*365 || ' days')::interval
FROM ids, generate_series(1,500000);

ANALYZE;

-- 2. VERIFY ROW COUNTS (expected: 10001 | 10001 | 500000)
SELECT (SELECT count(*) FROM customers)    AS customers,
       (SELECT count(*) FROM accounts)     AS accounts,
       (SELECT count(*) FROM transactions) AS transactions;

-- 3. QUERY: account statement for account 500 (returned 58 rows)
SELECT * FROM transactions WHERE account_id = 500 ORDER BY created_at DESC;

-- 4. BEFORE INDEX: Parallel Seq Scan + Sort, Execution Time 41.622 ms
EXPLAIN ANALYZE
SELECT * FROM transactions WHERE account_id = 500 ORDER BY created_at DESC;

-- 5. OPTIMISATION: composite B-tree index (filter column, then sort column)
CREATE INDEX idx_txn_acct_date ON transactions(account_id, created_at DESC);
ANALYZE transactions;

-- 6. AFTER INDEX: Index Scan, no Sort, Execution Time 1.735 ms
EXPLAIN ANALYZE
SELECT * FROM transactions WHERE account_id = 500 ORDER BY created_at DESC;

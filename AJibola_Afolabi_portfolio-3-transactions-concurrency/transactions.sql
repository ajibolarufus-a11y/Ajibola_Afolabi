-- Portfolio 3: Transactions and Concurrency (NovaBank)
-- Test accounts: 500 and 501
-- Note: for the two-tab demos, run the long block in Tab 1, then the single UPDATE in Tab 2.

-- ============ SETUP ============
UPDATE accounts SET balance = 100000 WHERE account_id IN (500,501);
SELECT account_id, balance FROM accounts WHERE account_id IN (500,501) ORDER BY account_id;
-- Expected: 500 = 100000.00, 501 = 100000.00

-- ============ PART A: COMMIT ============
BEGIN;
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 500;
UPDATE accounts SET balance = balance + 10000 WHERE account_id = 501;
INSERT INTO transactions (account_id, txn_type, amount)
VALUES (500,'transfer_out',10000), (501,'transfer_in',10000);
COMMIT;
SELECT account_id, balance FROM accounts WHERE account_id IN (500,501) ORDER BY account_id;
-- Expected: 500 = 90000.00, 501 = 110000.00

-- ============ PART A: ROLLBACK ============
BEGIN;
UPDATE accounts SET balance = balance - 5000 WHERE account_id = 500;
UPDATE accounts SET balance = balance + 5000 WHERE account_id = 501;
ROLLBACK;
SELECT account_id, balance FROM accounts WHERE account_id IN (500,501) ORDER BY account_id;
-- Expected: unchanged (500 = 90000.00, 501 = 110000.00)

-- ============ DEMO 1: LOST UPDATE (the problem) ============
UPDATE accounts SET balance = 100000 WHERE account_id = 500;

-- TAB 1: run this, then switch to Tab 2 right away
DO $$
DECLARE b numeric;
BEGIN
  SELECT balance INTO b FROM accounts WHERE account_id = 500;   -- reads 100000
  PERFORM pg_sleep(30);                                         -- pause 30 seconds
  UPDATE accounts SET balance = b - 500 WHERE account_id = 500; -- writes using the OLD value
END $$;

-- TAB 2: run this while Tab 1 is still loading
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 500;

-- TAB 1: check afterwards
SELECT account_id, balance FROM accounts WHERE account_id = 500;
-- Result: 99500.00 (correct would be 98500.00, the 1000 withdrawal was lost)

-- ============ DEMO 2: FIX WITH SELECT ... FOR UPDATE ============
UPDATE accounts SET balance = 100000 WHERE account_id = 500;

-- TAB 1: run this, then switch to Tab 2 (the only change is FOR UPDATE)
DO $$
DECLARE b numeric;
BEGIN
  SELECT balance INTO b FROM accounts WHERE account_id = 500 FOR UPDATE;  -- locks the row
  PERFORM pg_sleep(30);
  UPDATE accounts SET balance = b - 500 WHERE account_id = 500;
END $$;

-- TAB 2: run after about 5 seconds (it WAITS for Tab 1's lock)
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 500;

-- TAB 1: check afterwards
SELECT account_id, balance FROM accounts WHERE account_id = 500;
-- Result: 98500.00 (correct)

-- ============ DEMO 3: ISOLATION LEVELS ============
CREATE TABLE demo_log (note TEXT);

-- 3a. READ COMMITTED (default)
UPDATE accounts SET balance = 100000 WHERE account_id = 500;
TRUNCATE demo_log;

-- TAB 1:
BEGIN;
INSERT INTO demo_log SELECT 'READ COMMITTED - first read: ' || balance FROM accounts WHERE account_id = 500;
SELECT pg_sleep(30);
INSERT INTO demo_log SELECT 'READ COMMITTED - second read: ' || balance FROM accounts WHERE account_id = 500;
COMMIT;
SELECT * FROM demo_log;

-- TAB 2 (after about 5 seconds):
UPDATE accounts SET balance = balance - 5000 WHERE account_id = 500;
-- Result: first read 100000.00, second read 95000.00 (value changed mid-transaction)

-- 3b. REPEATABLE READ
UPDATE accounts SET balance = 100000 WHERE account_id = 500;
TRUNCATE demo_log;

-- TAB 1:
BEGIN ISOLATION LEVEL REPEATABLE READ;
INSERT INTO demo_log SELECT 'REPEATABLE READ - first read: ' || balance FROM accounts WHERE account_id = 500;
SELECT pg_sleep(30);
INSERT INTO demo_log SELECT 'REPEATABLE READ - second read: ' || balance FROM accounts WHERE account_id = 500;
COMMIT;
SELECT * FROM demo_log;

-- TAB 2 (after about 5 seconds):
UPDATE accounts SET balance = balance - 5000 WHERE account_id = 500;
-- Result: first read 100000.00, second read 100000.00 (stable snapshot)

-- ============ CLEAN UP ============
UPDATE accounts SET balance = 100000 WHERE account_id IN (500,501);

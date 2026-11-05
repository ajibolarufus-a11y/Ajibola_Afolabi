-- Portfolio 5: Distributed and Cloud Database Exercise (NovaBank)

-- Part A: Sharding concept using hash partitioning on account_id
-- Step 1: partitioned table with 4 partitions
CREATE TABLE transactions_p (LIKE transactions) PARTITION BY HASH (account_id);
CREATE TABLE transactions_p0 PARTITION OF transactions_p FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE transactions_p1 PARTITION OF transactions_p FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE transactions_p2 PARTITION OF transactions_p FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE transactions_p3 PARTITION OF transactions_p FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- Step 2: copy the existing transactions into the partitioned table
INSERT INTO transactions_p SELECT * FROM transactions;

-- Step 3: how the rows were spread across the 4 partitions
SELECT tableoid::regclass AS partition, count(*) AS rows
FROM transactions_p GROUP BY 1 ORDER BY 1;

-- Step 4: partition pruning (the plan should name only ONE partition)
EXPLAIN SELECT * FROM transactions_p WHERE account_id = 500;

-- Part B: server role check
-- is_replica = false means this is the primary server that accepts writes.
-- wal_level = logical means replication can be built on top of this server.
SELECT version(), pg_is_in_recovery() AS is_replica, current_setting('wal_level') AS wal_level;

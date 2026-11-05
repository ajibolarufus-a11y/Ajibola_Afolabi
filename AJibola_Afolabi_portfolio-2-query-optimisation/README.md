# Portfolio 2: Query Processing and Optimisation

**Course:** MIT 8103 Advanced Database Systems
**Case study:** NovaBank (simulated Nigerian fintech/bank)
**Platform used:** Supabase (PostgreSQL)

---

## 1. Objective

To show how an index changes the way PostgreSQL executes a query on a large table, using execution plans as evidence.

## 2. Data Used

A small table makes execution plans meaningless, so I generated test data with `generate_series()` and `random()`:

| Table        | Rows    |
| ------------ | ------- |
| customers    | 10,001  |
| accounts     | 10,001  |
| transactions | 500,000 |

Evidence: `screenshots/01-row-count.png`

After loading, I ran `ANALYZE` so PostgreSQL had up-to-date statistics for choosing plans.

## 3. The Query

An account statement: all transactions for one account, newest first. This is one of the most common operations in a bank.

```sql
SELECT * FROM transactions
WHERE account_id = 500
ORDER BY created_at DESC;
```

The query returned **58 rows**. Evidence: `screenshots/02-query-result.png`

## 4. Before the Index

I ran `EXPLAIN ANALYZE` on the query with no index on `account_id`.

| Item                   | Result                                      |
| ---------------------- | ------------------------------------------- |
| Scan type              | Parallel Seq Scan on `transactions`         |
| Rows removed by filter | 249,971 per worker (about 500,000 in total) |
| Rows kept              | 58                                          |
| Extra step             | Separate Sort on `created_at DESC`          |
| **Execution time**     | **41.622 ms**                               |

PostgreSQL had to read the whole table and discard almost every row to find the 58 that belong to one account, then sort them.

Evidence: `screenshots/03-before-index.png`

## 5. The Optimisation

I created a composite B-tree index:

```sql
CREATE INDEX idx_txn_acct_date ON transactions(account_id, created_at DESC);
ANALYZE transactions;
```

Why this index: `account_id` serves the `WHERE` filter, and `created_at DESC` matches the `ORDER BY`, so PostgreSQL can read the rows already in the right order.

## 6. After the Index

I ran the same `EXPLAIN ANALYZE` again.

| Item               | Result                               |
| ------------------ | ------------------------------------ |
| Scan type          | Index Scan using `idx_txn_acct_date` |
| Index condition    | `account_id = 500`                   |
| Rows returned      | 58                                   |
| Extra step         | None (no Sort needed)                |
| **Execution time** | **1.735 ms**                         |

Evidence: `screenshots/04-after-index.png`

## 7. Performance Analysis

|                | Before index             | After index           |
| -------------- | ------------------------ | --------------------- |
| Plan           | Parallel Seq Scan + Sort | Index Scan            |
| Execution time | 41.622 ms                | 1.735 ms              |
| Improvement    | n/a                      | about 24 times faster |

Before the index, the query took 41.622 ms because PostgreSQL scanned all 500,000 rows to find the transactions of one account and then sorted them. After the composite index, it took 1.735 ms: the index lets PostgreSQL jump straight to the matching rows, already in order, so the full table scan and the Sort step disappeared.

**Trade-off:** an index uses extra storage and makes every insert slightly slower, because the index must be updated too. For a bank ledger that is read far more often than it is written per account, this cost is worth paying, but indexes should be added for real query patterns rather than on every column.

## 8. Files in this Folder

```
portfolio-2-query-optimisation/
├── queries.sql
├── screenshots/
│   ├── 01-row-count.png
│   ├── 02-query-result.png
│   ├── 03-before-index.png
│   └── 04-after-index.png
└── README.md
```

## 9. How to Reproduce

1. Run the seed section of `queries.sql` once (never twice, to avoid duplicate data).
2. Run `ANALYZE;`.
3. Run the `EXPLAIN ANALYZE` query and note the plan and time.
4. Create the index, run `ANALYZE transactions;`, and run the `EXPLAIN ANALYZE` query again.

## 10. Short Reflection

In this portfolio I learned how to read an execution plan and how an index changes the way PostgreSQL finds data. Before the index, the plan showed a Parallel Seq Scan that read about 500,000 rows to return only 58, and the query took 41.622 ms. After I created the composite index on `(account_id, created_at DESC)`, the plan changed to an Index Scan and the time dropped to 1.735 ms, about 24 times faster. I chose that column order on purpose: `account_id` is used in the WHERE filter and `created_at` in the ORDER BY, so PostgreSQL no longer needs a separate Sort step.

One challenge I faced was a duplicate-key error when I tried to seed the customers table a second time. I solved it by checking the row counts first, which showed the data was already loaded, so I skipped the seed steps and continued. This taught me to verify the state of the database before re-running scripts.

I also learned that indexes have a cost. They use extra storage and slow down inserts slightly, so they should be created for real query patterns, such as an account statement in a bank, and not on every column.

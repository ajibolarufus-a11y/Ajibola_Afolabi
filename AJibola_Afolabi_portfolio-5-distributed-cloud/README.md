# Portfolio 5: Distributed and Cloud Database Exercise

**Course:** MIT 8103 Advanced Database Systems
**Case study:** NovaBank (simulated Nigerian fintech/bank)
**Platform used:** Supabase (hosted PostgreSQL, free tier)

---

## 1. Objective

A real bank cannot depend on one server. This portfolio shows the main distributed database ideas (sharding, replication, availability and consistency) for NovaBank. The free Supabase tier runs a single primary server, so I demonstrate **sharding with partitioning** and **cloud deployment evidence**, and I **discuss** replication and multi-region design instead of claiming to have built them.

The full script is in [`partitioning.sql`](partitioning.sql).

---

## 2. Part A: Sharding Concept (Hash Partitioning)

Sharding splits a large table into smaller pieces by a key. Inside one PostgreSQL database these pieces are called partitions. In a distributed system, each piece would live on its own server.

I created `transactions_p`, a copy of the 500,000-row `transactions` table, partitioned by `HASH (account_id)` into 4 partitions:

```sql
CREATE TABLE transactions_p (LIKE transactions) PARTITION BY HASH (account_id);
CREATE TABLE transactions_p0 PARTITION OF transactions_p FOR VALUES WITH (MODULUS 4, REMAINDER 0);
-- ... p1, p2 and p3 in the same way
INSERT INTO transactions_p SELECT * FROM transactions;
```

**Row distribution** (`screenshots/01-partition-spread.png`):

| Partition | Rows |
|---|---|
| transactions_p0 | 124,310 |
| transactions_p1 | 126,461 |
| transactions_p2 | 126,013 |
| transactions_p3 | 123,218 |

The four counts add up to 500,002 rows, the same as the original table. The hash function spread the rows roughly evenly, so no single partition holds most of the data. A good shard key does this. `account_id` is a good key for a bank because most queries (a statement, a balance check, a transfer) are about one account.

**Partition pruning** (`screenshots/02-partition-pruning.png`): for `WHERE account_id = 500`, the query plan scanned **only `transactions_p3`** and ignored the other three. (It still did a sequential scan inside that one partition, because the indexes of the original table were not copied by `LIKE`.) The database knows which partition holds account 500 from the hash of the key. In a real sharded system, this means a query goes to one server instead of all of them.

**Limitations:** this is partitioning inside one server, not true sharding across servers, so it improves organisation and query speed but not capacity or fault tolerance. Also, `LIKE` copies only the column definitions, so `transactions_p` does not have the primary key, foreign keys or CHECK constraints of the original table. A production design would define them.

---

## 3. Part B: Replication and Server Role

I checked the role of the server:

```sql
SELECT version(), pg_is_in_recovery() AS is_replica, current_setting('wal_level') AS wal_level;
```

Result (`screenshots/03-server-role.png`):

| Value | Result |
|---|---|
| version | PostgreSQL 17.11 on x86_64-pc-linux-gnu |
| is_replica | false |
| wal_level | logical |

`is_replica = false` means this server is the **primary**, which accepts writes. `wal_level` controls how much detail PostgreSQL records in its write-ahead log, and the `logical` setting is what allows replication to be built on top of it.

**Replication in NovaBank's design:** the free tier has no read replica, so I did not set one up. In a production design, the primary would stream its changes to one or more replicas. Replicas would serve read-heavy work such as statements and reports, and one of them could be promoted if the primary failed.

---

## 4. Part C: Cloud Deployment Evidence

- **Region:** the project runs in the **West EU (Ireland), `eu-west-1`** region on a Nano compute size (`screenshots/04-region.png`). The dashboard also shows the primary database using 6 of 60 connections. Because the servers are in Europe, users in Nigeria see extra network latency, so for a real bank the region should be chosen as close to the customers as possible.
- **Backups and connection pooling:** *(delete this bullet if you do not have screenshots 05 and 06)* the backups page and the connection pooler settings are shown in `screenshots/05-backups.png` and `screenshots/06-pooling.png`. A connection pooler (Supavisor) lets many application connections share a small number of database connections, which protects the server under heavy load.

---

## 5. Discussion

**Sharding.** If NovaBank grew to hundreds of millions of transactions, one server would not be enough. Hash-sharding `transactions` by `account_id` would spread the data and the load across servers, and each account's history would stay on one shard. The difficulty is a transfer between accounts on different shards, because it becomes a distributed transaction that needs a coordination protocol such as two-phase commit, which is slower and more complex than the single-server transfer I tested in Portfolio 3.

**Replication and availability.** A primary with replicas gives two benefits: reads can be spread across replicas, and the system survives a server failure because a replica can take over. Availability can be improved further with replicas in a second region, with regular backups, and with point-in-time recovery.

**Consistency and the CAP theorem.** When a network failure splits a distributed system, it must choose between consistency (every user sees the same, correct data) and availability (every request gets an answer). A bank should choose **consistency** (a CP system): it is better to temporarily refuse a transaction than to show a wrong balance or allow a double spend. Replication also has a cost here. With asynchronous replication, a replica can lag behind the primary, so it could show an old balance. For this reason, balance checks before a withdrawal must go to the primary, and replicas should be used only for work that tolerates slightly old data, such as statements and reports.

**Link to my earlier portfolios.** Portfolio 3 showed that a lost update corrupts a balance and that locking fixes it on one server. Distributing the data makes that problem harder, which is why consistency matters most for NovaBank's ledger. Portfolio 4's fraud alerts in MongoDB are a good candidate to scale out separately, because they are read as whole documents and do not need cross-account transactions.

---

## 6. Files in this Folder

```
portfolio-5-distributed-cloud/
├── partitioning.sql
├── screenshots/
│   ├── 01-partition-spread.png
│   ├── 02-partition-pruning.png
│   ├── 03-server-role.png
│   ├── 04-region.png
│   ├── 05-backups.png      (if available)
│   └── 06-pooling.png      (if available)
└── README.md
```

## 7. How to Reproduce

1. Run `partitioning.sql` in the Supabase SQL Editor, one statement at a time.
2. Compare the partition counts and the `EXPLAIN` plan with Section 2.
3. Take the region screenshot from Project Settings → General.

---

## 8. Short Reflection

In this portfolio I learned that scaling a database is mostly about deciding where data lives. Partitioning `transactions` by `account_id` showed me how a good key spreads rows evenly and how a query for one account touches only one partition. I also learned the limits of what I built: partitioning on one server improves organisation and speed, but it does not give extra capacity or protect against a server failure, so I explained replication and multi-region design in the discussion instead of claiming to have built them.

The most important idea for me was the trade-off between consistency and availability. After seeing in Portfolio 3 how easily a balance can be corrupted, I understood why a bank should choose consistency, accept the cost of slower distributed transactions, and send balance-critical reads to the primary.

A challenge was that the free tier has no read replica or scheduled backups, so I could not demonstrate everything. I decided to be clear about what I had actually done and what I had only discussed, because that is more honest and shows that I understand the difference.

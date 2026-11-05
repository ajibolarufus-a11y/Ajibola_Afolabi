# Portfolio 3: Transactions and Concurrency

**Course:** MIT 8103 Advanced Database Systems
**Case study:** NovaBank (simulated Nigerian fintech/bank)
**Platform used:** Supabase (PostgreSQL), SQL Editor with two query tabs

---

## 1. Objective

A bank transfer must either happen completely or not at all (atomicity), and two users working on the same account at the same time must not corrupt the balance (isolation). This portfolio demonstrates:

1. COMMIT and ROLLBACK
2. A concurrency problem (lost update)
3. A control mechanism (row locking with `SELECT ... FOR UPDATE`)
4. Isolation levels (READ COMMITTED vs REPEATABLE READ)

All tests use accounts **500** and **501**, with starting balances set to 100,000.00. The SQL Editor runs each tab as a separate session, so two tabs were used to create overlapping transactions, and `pg_sleep()` was used to hold a transaction open long enough to overlap.

The full script is in [`transactions.sql`](transactions.sql).

---

## 2. Part A: COMMIT and ROLLBACK

**Starting balances:** account 500 = 100,000.00 and account 501 = 100,000.00 (`screenshots/01-start-balances.png`)

**COMMIT test:** a ₦10,000 transfer from account 500 to 501, wrapped in `BEGIN ... COMMIT`, with two matching rows written to `transactions`.

| Account | Balance after COMMIT |
|---|---|
| 500 | 90,000.00 |
| 501 | 110,000.00 |

The change was saved permanently. Evidence: `screenshots/02-commit.png`

**ROLLBACK test:** a ₦5,000 transfer wrapped in `BEGIN ... ROLLBACK`.

| Account | Balance after ROLLBACK |
|---|---|
| 500 | 90,000.00 |
| 501 | 110,000.00 |

The balances did not change, so the whole transfer was undone. Evidence: `screenshots/03-rollback.png`

**Conclusion:** both updates in a transfer succeed together or fail together. This is **atomicity**, and it prevents money from being deducted from one account without reaching the other.

---

## 3. Part B: Concurrency Problem (Lost Update)

**Setup:** account 500 reset to 100,000.00.

| Step | Tab 1 | Tab 2 |
|---|---|---|
| 1 | Reads balance (100,000) and pauses 30 seconds | |
| 2 | | Withdraws 1,000 and saves (balance becomes 99,000) |
| 3 | Writes 100,000 − 500 = 99,500 using its old value | |

**Result:** the final balance was **99,500.00**. The correct balance is **98,500.00** (100,000 − 500 − 1,000). Tab 2's ₦1,000 withdrawal was erased.

**Why it happened:** Tab 1 calculated its new balance from a value that had already become out of date, and its write overwrote Tab 2's change. This is the **lost update** problem.

Evidence: `screenshots/04-lost-update.png`

---

## 4. Part C: Control Mechanism (`SELECT ... FOR UPDATE`)

The same test was repeated with one change: Tab 1 read the balance with `FOR UPDATE`, which locks the row.

- Tab 2's `UPDATE` did **not** finish immediately. It stayed in the loading state, waiting for Tab 1's lock to be released. Evidence: `screenshots/05-lock-waiting.png`
- After Tab 1 committed, Tab 2 applied its withdrawal to the updated balance.
- The final balance was **98,500.00**, which is correct. Evidence: `screenshots/06-fix-final-balance.png`

**Conclusion:** row-level locking makes concurrent transactions take turns on the same row, so no update is lost. The cost is that the second user waits, so locks should be held for as short a time as possible.

---

## 5. Part D: Isolation Levels

A log table, `demo_log`, was used to record what a transaction read at two different times, while another tab changed the balance in between (a ₦5,000 withdrawal).

| Isolation level | First read | Second read | Behaviour |
|---|---|---|---|
| READ COMMITTED (default) | 100,000.00 | 95,000.00 | The value changed in the middle of the transaction. |
| REPEATABLE READ | 100,000.00 | 100,000.00 | The transaction kept seeing the same snapshot. |

Evidence: `screenshots/07-read-committed.png` and `screenshots/08-repeatable-read.png`

**Conclusion:** READ COMMITTED always shows the latest committed data, which is fast but can give two different answers inside one transaction. REPEATABLE READ gives a consistent view for the whole transaction, which is better for audits and reports. The stricter level can cause serialization errors that the application must retry.

---

## 6. Files in this Folder

```
portfolio-3-transactions-concurrency/
├── transactions.sql
├── screenshots/
│   ├── 01-start-balances.png
│   ├── 02-commit.png
│   ├── 03-rollback.png
│   ├── 04-lost-update.png
│   ├── 05-lock-waiting.png
│   ├── 06-fix-final-balance.png
│   ├── 07-read-committed.png
│   └── 08-repeatable-read.png
└── README.md
```

## 7. How to Reproduce

1. Open the SQL Editor and create a second query tab.
2. Run the Part A statements in one tab.
3. For each concurrency demo, run the `DO $$ ... $$` block (or the isolation block) in Tab 1, switch to Tab 2 within a few seconds, run the single `UPDATE`, then check the result in Tab 1.
4. Reset the balances before each demo.

---

## 8. Short Reflection

In this portfolio I learned that correctness in a bank depends on more than good tables. A transfer has two updates, and wrapping them in a transaction means they either both happen or neither does, as the COMMIT and ROLLBACK tests showed.

The concurrency tests were the most useful part. Using two tabs and `pg_sleep()`, I reproduced a lost update on purpose: the final balance was 99,500.00 instead of 98,500.00, so a ₦1,000 withdrawal silently disappeared with no error message. That showed me why this kind of bug is dangerous, because the database does not warn you. Adding `FOR UPDATE` fixed it: the second tab waited for the lock and the final balance was correct.

I also compared isolation levels. READ COMMITTED let the balance change between two reads in the same transaction, while REPEATABLE READ kept a stable snapshot. For a bank, I would use stronger isolation or locking for balance changes and audits, and accept the slightly slower speed.

A challenge I faced was that accounts 1 and 2 did not exist, because the failed inserts in Portfolio 1 used up the first ID numbers. I checked the table, found accounts 500 and 501, and used them instead. I also had to retry the lost-update demo once, because the timing between the two tabs did not overlap the first time. This taught me that concurrency problems depend on timing, which is why they are hard to find in real systems.

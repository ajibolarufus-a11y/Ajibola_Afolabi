# Advanced Database Systems Portfolio (MIT 8103)

**Course:** MIT 8103 Advanced Database Systems, 2026/2027 First Semester
**Student:** Ajibola Afolabi (301918643)

## Selected Organisation

**NovaBank**, a simulated Nigerian fintech/bank.

- **Nature of the system:** retail banking platform for savings accounts, deposits, withdrawals and transfers.
- **Users:** customers, tellers and auditors.
- **Major data:** customers, accounts, transactions, KYC details and fraud alerts.
- **Key operations:** open account, deposit, withdraw, transfer funds, reverse failed transactions, audit balances.

All five portfolios use this same case study.

## Technologies

- Supabase (PostgreSQL 17) for Portfolios 1, 2, 3, 4 (JSONB) and 5
- MongoDB Atlas (free M0 cluster) for Portfolio 4
- dbdiagram.io for the ER diagram

## Portfolio Index

| Portfolio | Topic | Folder | Key result |
|---|---|---|---|
| 1 | Database design and modelling | [AJibola_Afolabiportfolio-1-database-design](AJibola_Afolabiportfolio-1-database-design/) | 3 tables in 3NF; keys and constraints proven with 23505, 23503 and 23514 errors |
| 2 | Query processing and optimisation | [AJibola_Afolabi_portfolio-2-query-optimisation](AJibola_Afolabi_portfolio-2-query-optimisation/) | Composite index cut a query from 41.622 ms (Seq Scan) to 1.735 ms (Index Scan) |
| 3 | Transactions and concurrency | [AJibola_Afolabi_portfolio-3-transactions-concurrency](AJibola_Afolabi_portfolio-3-transactions-concurrency/) | COMMIT/ROLLBACK; lost update (99,500 vs 98,500) fixed with `FOR UPDATE`; isolation levels compared |
| 4 | NoSQL and advanced data models | [AJibola_Afolabi_portfolio-4-nosql](AJibola_Afolabi_portfolio-4-nosql/) | JSONB with GIN index; MongoDB `fraud_alerts` collection |
| 5 | Distributed and cloud database | AJibola_Afolabi_[portfolio-5-distributed-cloud](AJibola_Afolabi_portfolio-5-distributed-cloud/) | Hash partitioning into 4 partitions with pruning; replication and CAP discussed |

## Repository Structure

```
advanced-database-portfolio/
├── AJibola_Afolabiportfolio-1-database-design/
├── AJibola_Afolabi_portfolio-2-query-optimisation/
├── AJibola_Afolabi_portfolio-3-transactions-concurrency/
├── AJibola_Afolabi_portfolio-4-nosql/
├── AJibola_Afolabi_portfolio-5-distributed-cloud/
└── README.md
```

Each folder has its own README that explains what was done, how it was tested, and where the screenshot evidence is.

## How to Review

1. Start with each portfolio's `README.md`.
2. Run the `.sql` files in the Supabase SQL Editor, one statement at a time, as described in each README.
3. Compare the results with the screenshots in each `screenshots/` folder.

## AI Use Declaration

- **Tool used:** Claude (Anthropic).
- **Used for:** explaining the brief, suggesting the step order, drafting SQL scripts and README text, and explaining query plans and error messages.
- **Verification:** I ran every statement myself in Supabase and MongoDB Atlas, took all screenshots from my own results, compared each output with what was expected, and fixed the problems that appeared.

## References

- PostgreSQL 17 Documentation: https://www.postgresql.org/docs/
- Supabase Documentation: https://supabase.com/docs
- MongoDB Atlas Documentation: https://www.mongodb.com/docs/atlas/
- dbdiagram.io: https://dbdiagram.io

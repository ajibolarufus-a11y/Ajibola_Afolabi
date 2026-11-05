# Portfolio 4: NoSQL and Advanced Data Models

**Course:** MIT 8103 Advanced Database Systems
**Case study:** NovaBank (simulated Nigerian fintech/bank)
**Platforms used:** Supabase (PostgreSQL JSONB) and MongoDB Atlas (free M0 cluster)

---

## 1. Objective

The money ledger in NovaBank is relational, but some of its data is flexible and nested: customer KYC details and fraud alerts. This portfolio models that data with two document-style approaches and explains why each one suits the data.

| Part | Technology | Data modelled |
|---|---|---|
| A | PostgreSQL JSONB (document model inside a relational database) | Customer KYC details |
| B | MongoDB Atlas (document database) | Fraud alerts |

---

## 2. Part A: JSONB in Supabase

The `customers` table (Portfolio 1) has a `kyc_data` column of type JSONB. KYC information differs between customers (different tiers, devices, and address details), so a fixed set of columns would be wasteful.

**Documents stored** (see [`jsonb.sql`](jsonb.sql)):

```json
{"bvn_verified": true, "tier": 2, "devices": ["ios","android"], "address": {"city":"Lagos","state":"Lagos"}}
```

Three customers were given KYC documents with a nested `address` object and a `devices` array. Evidence: `screenshots/01-jsonb-data.png`

**GIN index:** I created a GIN index so that searches inside the JSON do not need to scan every row.

```sql
CREATE INDEX idx_kyc ON customers USING GIN (kyc_data);
```

Evidence: `screenshots/02-gin-index.png`

**Queries:**

| Query | What it does | Result |
|---|---|---|
| `WHERE kyc_data @> '{"bvn_verified": true}'` | The `@>` operator checks whether the document contains this value. | 2 customers (Ada Obi and Customer 2) |
| `kyc_data->'address'->>'city'` | Reads a value from inside the nested `address` object. | Lagos, Abuja and Ibadan |

Evidence: `screenshots/03-jsonb-contains.png` and `screenshots/04-jsonb-nested.png`

---

## 3. Part B: MongoDB Atlas

I created a free M0 cluster, a database called `novabank`, and a collection called `fraud_alerts` with four documents (see [`fraud_alerts.json`](fraud_alerts.json)). Evidence: `screenshots/05-atlas-collection.png`

Example document:

```json
{
  "account_id": 500,
  "alert_type": "large_transfer",
  "amount": 450000,
  "severity": "high",
  "status": "open",
  "device": { "type": "android", "ip": "102.89.12.4" },
  "location": { "city": "Lagos", "country": "NG" },
  "notes": ["Above daily limit", "New beneficiary"]
}
```

The documents **do not all have the same fields**. Only some have `amount`, `attempts`, `notes` or `resolved_by`, because different kinds of alert carry different details. MongoDB stores each document as it is.

**Queries** (also in [`mongo-queries.txt`](mongo-queries.txt)):

| Filter | Result |
|---|---|
| `{ "severity": "high" }` | 2 documents (large transfer and foreign login) |
| `{ "location.city": "Lagos" }` | 1 document (searches inside the nested `location` object) |

Evidence: `screenshots/06-atlas-severity-query.png` and `screenshots/07-atlas-nested-query.png`

---

## 4. Why These Models Suit the Data (Suitability)

**Documents suit KYC details and fraud alerts because:**
- The structure varies. A new alert type or a new KYC field can be added without altering a table or migrating existing rows.
- The data is nested. A customer's address and an alert's device and location belong together, so one document holds them and no joins are needed to read a complete alert.
- Arrays are natural. A list of devices or notes sits inside the document instead of needing a separate table.
- Alerts are read as whole records, which is what a document store is optimised for.

**Relational tables still suit the money ledger because:**
- Balances and transactions need ACID guarantees. Portfolio 3 showed that a transfer must be atomic and that concurrent updates must be controlled with locking.
- The data is fixed and well structured, and constraints (CHECK, UNIQUE, foreign keys from Portfolio 1) protect it.

**JSONB versus MongoDB:** JSONB keeps flexible data next to the relational data in one system, so it can be joined to `customers` and covered by the same backups and transactions. MongoDB is a better fit when the flexible data grows large and is queried on its own, such as a stream of fraud alerts, and it can be scaled out separately.

**Trade-offs:** JSON data has no enforced schema, so bad or inconsistent fields can enter unless the application validates them. Keeping the same information in two systems (Supabase and MongoDB) also means it must be kept consistent by the application, because there are no cross-database foreign keys. For this reason `account_id` in `fraud_alerts` is a reference by value only.

---

## 5. Files in this Folder

```
portfolio-4-nosql/
├── jsonb.sql
├── fraud_alerts.json
├── mongo-queries.txt
├── screenshots/
│   ├── 01-jsonb-data.png
│   ├── 02-gin-index.png
│   ├── 03-jsonb-contains.png
│   ├── 04-jsonb-nested.png
│   ├── 05-atlas-collection.png
│   ├── 06-atlas-severity-query.png
│   └── 07-atlas-nested-query.png
└── README.md
```

## 6. How to Reproduce

1. **Part A:** run `jsonb.sql` in the Supabase SQL Editor, one statement at a time.
2. **Part B:** create a free M0 cluster in MongoDB Atlas, create the database `novabank` and the collection `fraud_alerts`, insert the documents from `fraud_alerts.json` using the JSON view, and run the filters from `mongo-queries.txt`.

---

## 7. Short Reflection

In this portfolio I learned that choosing a data model depends on the shape of the data. The ledger, with balances and transfers, belongs in relational tables where constraints and transactions protect the money. KYC details and fraud alerts are different: they vary from record to record and contain nested objects and lists, so a document model fits them better.

Using JSONB with a GIN index showed me that PostgreSQL can act as a document store, which is convenient because the flexible data stays in the same database as the customer records. Using MongoDB Atlas showed me the other side: I could insert alerts with different fields without defining a schema first, and I could query a nested field directly with `location.city`.

The main challenge was understanding the trade-off. A flexible model is easy to change, but nothing forces the data to be consistent, and keeping information in two systems means the application has to keep the two in step. For a real bank I would keep all money movement in the relational database and use document storage only for supporting data such as alerts and KYC details.

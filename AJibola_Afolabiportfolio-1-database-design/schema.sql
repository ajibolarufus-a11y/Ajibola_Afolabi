CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  full_name   TEXT NOT NULL,
  email       TEXT UNIQUE NOT NULL,
  kyc_data    JSONB,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE accounts (
  account_id  SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(customer_id),
  acct_number CHAR(10) UNIQUE NOT NULL,
  balance     NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
  status      TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','frozen','closed'))
);

CREATE TABLE transactions (
  txn_id      BIGSERIAL PRIMARY KEY,
  account_id  INT NOT NULL REFERENCES accounts(account_id),
  txn_type    TEXT NOT NULL CHECK (txn_type IN ('deposit','withdrawal','transfer_in','transfer_out','reversal')),
  amount      NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  created_at  TIMESTAMPTZ DEFAULT now()
);
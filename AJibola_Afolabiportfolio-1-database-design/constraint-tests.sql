-- 4a. Valid insert (expected: success)
INSERT INTO customers (full_name, email) VALUES ('Ada Obi', 'ada@mail.com');

-- 4b. Duplicate email (expected: ERROR 23505 unique violation)
INSERT INTO customers (full_name, email) VALUES ('Another Ada', 'ada@mail.com');

-- 4c. Non-existent customer (expected: ERROR 23503 foreign key violation)
INSERT INTO accounts (customer_id, acct_number) VALUES (999, '0000000001');

-- 4d. Negative balance (expected: ERROR 23514 check violation)
INSERT INTO accounts (customer_id, acct_number, balance) VALUES (1, '0000000002', -500);
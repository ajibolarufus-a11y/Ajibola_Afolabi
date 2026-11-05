-- Portfolio 4: NoSQL and Advanced Data Models (NovaBank)
-- Part A: JSONB document model in PostgreSQL (Supabase)

-- 1. Store flexible KYC documents in the kyc_data JSONB column
UPDATE customers SET kyc_data = '{"bvn_verified": true, "tier": 2, "devices": ["ios","android"], "address": {"city":"Lagos","state":"Lagos"}}' WHERE email = 'ada@mail.com';
UPDATE customers SET kyc_data = '{"bvn_verified": false, "tier": 1, "devices": ["android"], "address": {"city":"Abuja","state":"FCT"}}' WHERE email = 'user1@mail.com';
UPDATE customers SET kyc_data = '{"bvn_verified": true, "tier": 3, "devices": ["web"], "address": {"city":"Ibadan","state":"Oyo"}}' WHERE email = 'user2@mail.com';

-- 2. View the documents (expected: 3 rows)
SELECT full_name, email, kyc_data FROM customers WHERE kyc_data IS NOT NULL;

-- 3. GIN index: makes searches inside JSONB fast
CREATE INDEX idx_kyc ON customers USING GIN (kyc_data);

-- 4a. Containment query with @> (expected: 2 rows, Ada Obi and Customer 2)
SELECT full_name, email FROM customers WHERE kyc_data @> '{"bvn_verified": true}';

-- 4b. Nested field access with -> and ->> (expected: Lagos, Abuja, Ibadan)
SELECT full_name, kyc_data->'address'->>'city' AS city FROM customers WHERE kyc_data IS NOT NULL;

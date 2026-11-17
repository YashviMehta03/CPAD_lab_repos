-- Step 6: credentials move to Supabase Auth. users.auth_id links a CampusSphere profile to its
-- Supabase Auth account; passwords are no longer stored here.
ALTER TABLE users ADD COLUMN auth_id UUID UNIQUE;
ALTER TABLE users DROP COLUMN password_hash;

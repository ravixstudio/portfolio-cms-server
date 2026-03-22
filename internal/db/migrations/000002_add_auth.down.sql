-- Restore comments columns
ALTER TABLE projects.comments ADD COLUMN author_name TEXT;
ALTER TABLE projects.comments ADD COLUMN author_email TEXT;
ALTER TABLE projects.comments DROP COLUMN visitor_id;

-- Restore likes columns
ALTER TABLE projects.likes ADD COLUMN visitor_hash TEXT;
ALTER TABLE projects.likes DROP COLUMN visitor_id;
ALTER TABLE projects.likes DROP CONSTRAINT likes_unique_per_reader;
-- Note: You may need to manually restore the original UNIQUE constraint on blog_id and visitor_hash

-- Drop Auth Tables
DROP TABLE IF EXISTS projects.visitors;
DROP TABLE IF EXISTS users.oauth_accounts;
DROP TYPE IF EXISTS users.oauth_provider;
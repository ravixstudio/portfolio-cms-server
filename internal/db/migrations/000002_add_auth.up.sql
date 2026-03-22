-- Support for multiple auth providers for Platform Users (CMS Admins)
CREATE TYPE users.oauth_provider AS ENUM ('google', 'github');

CREATE TABLE users.oauth_accounts
(
    id          UUID PRIMARY KEY              DEFAULT gen_random_uuid(),
    user_id     UUID                 NOT NULL REFERENCES users.users (id) ON DELETE CASCADE,
    provider    users.oauth_provider NOT NULL,
    provider_id TEXT                 NOT NULL,
    created_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,
    UNIQUE (provider, provider_id),
    CONSTRAINT provider_id_not_blank CHECK (char_length(provider_id) > 0)
);

CREATE INDEX oauth_accounts_user_id_idx ON users.oauth_accounts (user_id);

-- Separate table for Project Visitors (Type 2 Auth - Email/Password only for MVP)
CREATE TABLE projects.visitors
(
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects.projects (id) ON DELETE CASCADE,
    email      TEXT NOT NULL,
    password   TEXT NOT NULL, -- Required for MVP since no OAuth for visitors
    firstname  TEXT,
    lastname   TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    UNIQUE (project_id, email),
    CONSTRAINT email_not_blank CHECK (char_length(email) > 0)
);

CREATE INDEX visitors_project_id_idx ON projects.visitors (project_id);
CREATE INDEX visitors_email_idx ON projects.visitors (email);

-- Update existing tables to use visitor_id
ALTER TABLE projects.likes ADD COLUMN visitor_id UUID REFERENCES projects.visitors (id) ON DELETE CASCADE;
ALTER TABLE projects.likes DROP COLUMN visitor_hash;
ALTER TABLE projects.likes DROP CONSTRAINT IF EXISTS likes_visitor_not_blank;
ALTER TABLE projects.likes DROP CONSTRAINT IF EXISTS likes_unique_per_reader;
ALTER TABLE projects.likes ADD CONSTRAINT likes_unique_per_reader UNIQUE (blog_id, visitor_id);

ALTER TABLE projects.comments ADD COLUMN visitor_id UUID REFERENCES projects.visitors (id) ON DELETE CASCADE;
ALTER TABLE projects.comments DROP COLUMN author_name;
ALTER TABLE projects.comments DROP COLUMN author_email;
ALTER TABLE projects.comments DROP CONSTRAINT IF EXISTS comments_author_name_not_blank;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS projects;

CREATE TYPE projects.blog_status AS ENUM ('draft', 'published');

-- ===========================================================================
-- users
-- ===========================================================================
CREATE TABLE users.users
(
    id         UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    email      TEXT        NOT NULL,
    password   TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_email_not_blank CHECK (length(trim(email)) > 0)
);

-- ===========================================================================
-- projects
-- ===========================================================================
CREATE TABLE projects.projects
(
    id         UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL
        REFERENCES users.users (id) ON DELETE CASCADE,
    name       TEXT        NOT NULL,
    slug       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT projects_name_not_blank CHECK (length(trim(name)) > 0),
    CONSTRAINT projects_slug_not_blank CHECK (length(trim(slug)) > 0),
    CONSTRAINT projects_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    CONSTRAINT projects_slug_unique UNIQUE (slug)
);

CREATE INDEX projects_user_id_idx ON projects.projects (user_id);

-- ===========================================================================
-- api keys
-- ===========================================================================
CREATE TABLE projects.api_keys
(
    id         UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    project_id UUID        NOT NULL
        REFERENCES projects.projects (id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL
        REFERENCES users.users (id) ON DELETE CASCADE,
    key_hash   TEXT        NOT NULL,
    label      TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT api_keys_key_hash_unique UNIQUE (key_hash),
    CONSTRAINT api_keys_label_len CHECK (label IS NULL OR char_length(label) <= 255)
);

CREATE INDEX api_keys_project_id_idx ON projects.api_keys (project_id);
CREATE INDEX api_keys_user_id_idx ON projects.api_keys (user_id);

CREATE INDEX api_keys_active_idx
    ON projects.api_keys (project_id)
    WHERE revoked_at IS NULL
      AND deleted_at IS NULL;

-- ===========================================================================
-- blogs
-- ===========================================================================
CREATE TABLE projects.blogs
(
    id              UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    project_id      UUID        NOT NULL
        REFERENCES projects.projects (id) ON DELETE CASCADE,
    title           TEXT        NOT NULL,
    slug            TEXT        NOT NULL,
    content         TEXT        NOT NULL,
    status          projects.blog_status NOT NULL DEFAULT 'draft',
    cover_image_url TEXT,
    seo_title       TEXT,
    seo_description TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at    TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ,
    CONSTRAINT blogs_title_not_blank CHECK (length(trim(title)) > 0),
    CONSTRAINT blogs_slug_not_blank CHECK (length(trim(slug)) > 0),
    CONSTRAINT blogs_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    CONSTRAINT blogs_published_at_consistency CHECK (
        (status = 'published' AND published_at IS NOT NULL)
        OR (status = 'draft')
    ),
    CONSTRAINT blogs_id_project_unique UNIQUE (id, project_id)
);

CREATE UNIQUE INDEX blogs_project_slug_active_uidx
    ON projects.blogs (project_id, slug)
    WHERE deleted_at IS NULL;

CREATE INDEX blogs_project_id_idx ON projects.blogs (project_id);
CREATE INDEX blogs_status_idx ON projects.blogs (status);

CREATE INDEX blogs_published_feed_idx
    ON projects.blogs (project_id, published_at DESC)
    WHERE status = 'published'
      AND deleted_at IS NULL;

-- ===========================================================================
-- tags
-- ===========================================================================
CREATE TABLE projects.tags
(
    id         UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    project_id UUID        NOT NULL
        REFERENCES projects.projects (id) ON DELETE CASCADE,
    name       TEXT        NOT NULL,
    slug       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT tags_name_not_blank CHECK (length(trim(name)) > 0),
    CONSTRAINT tags_slug_not_blank CHECK (length(trim(slug)) > 0),
    CONSTRAINT tags_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    CONSTRAINT tags_id_project_unique UNIQUE (id, project_id),
    CONSTRAINT tags_project_slug_unique UNIQUE (project_id, slug)
);

CREATE INDEX tags_project_id_idx ON projects.tags (project_id);

-- ===========================================================================
-- blog_tags
-- ===========================================================================
CREATE TABLE projects.blog_tags
(
    blog_id    UUID NOT NULL,
    tag_id     UUID NOT NULL,
    project_id UUID NOT NULL,
    PRIMARY KEY (blog_id, tag_id),
    CONSTRAINT blog_tags_blog_fk
        FOREIGN KEY (blog_id, project_id)
        REFERENCES projects.blogs (id, project_id)
        ON DELETE CASCADE,
    CONSTRAINT blog_tags_tag_fk
        FOREIGN KEY (tag_id, project_id)
        REFERENCES projects.tags (id, project_id)
        ON DELETE CASCADE
);

CREATE INDEX blog_tags_tag_id_idx ON projects.blog_tags (tag_id);
CREATE INDEX blog_tags_project_id_idx ON projects.blog_tags (project_id);

-- ===========================================================================
-- comments (no moderation status — remove unwanted rows with DELETE)
-- ===========================================================================
CREATE TABLE projects.comments
(
    id           UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    blog_id      UUID        NOT NULL
        REFERENCES projects.blogs (id) ON DELETE CASCADE,
    parent_id    UUID
        REFERENCES projects.comments (id) ON DELETE CASCADE,
    author_name  TEXT        NOT NULL,
    author_email TEXT,
    body         TEXT        NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT comments_body_not_blank CHECK (length(trim(body)) > 0),
    CONSTRAINT comments_author_name_not_blank CHECK (length(trim(author_name)) > 0)
);

CREATE INDEX comments_blog_id_idx ON projects.comments (blog_id);
CREATE INDEX comments_parent_id_idx ON projects.comments (parent_id);
CREATE INDEX comments_blog_created_idx ON projects.comments (blog_id, created_at);

CREATE OR REPLACE FUNCTION projects.enforce_comment_parent_same_blog()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    parent_blog_id UUID;
BEGIN
    IF NEW.parent_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT c.blog_id INTO parent_blog_id
    FROM projects.comments c
    WHERE c.id = NEW.parent_id;

    IF parent_blog_id IS NULL THEN
        RAISE EXCEPTION 'parent comment not found';
    END IF;

    IF parent_blog_id <> NEW.blog_id THEN
        RAISE EXCEPTION 'parent comment belongs to a different blog';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER comments_parent_same_blog_trg
    BEFORE INSERT OR UPDATE OF parent_id, blog_id
    ON projects.comments
    FOR EACH ROW
    EXECUTE FUNCTION projects.enforce_comment_parent_same_blog();

-- ===========================================================================
-- likes
-- ===========================================================================
CREATE TABLE projects.likes
(
    id           UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    blog_id      UUID        NOT NULL
        REFERENCES projects.blogs (id) ON DELETE CASCADE,
    visitor_hash TEXT        NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT likes_visitor_not_blank CHECK (length(trim(visitor_hash)) > 0),
    CONSTRAINT likes_unique_per_reader UNIQUE (blog_id, visitor_hash)
);

CREATE INDEX likes_blog_id_idx ON projects.likes (blog_id);

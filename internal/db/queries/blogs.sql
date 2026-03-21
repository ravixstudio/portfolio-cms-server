-- name: GetBlogByID :one
SELECT *
FROM projects.blogs
WHERE id = $1
  AND deleted_at IS NULL;

-- name: GetBlogByProjectAndSlug :one
SELECT *
FROM projects.blogs
WHERE project_id = $1
  AND slug = $2
  AND deleted_at IS NULL;

-- name: GetPublishedBlogByProjectAndSlug :one
SELECT *
FROM projects.blogs
WHERE project_id = $1
  AND slug = $2
  AND status = 'published'
  AND deleted_at IS NULL;

-- name: ListPublishedBlogsByProject :many
SELECT *
FROM projects.blogs
WHERE project_id = $1
  AND status = 'published'
  AND deleted_at IS NULL
ORDER BY published_at DESC NULLS LAST, created_at DESC;

-- name: ListBlogsByProject :many
SELECT *
FROM projects.blogs
WHERE project_id = $1
  AND deleted_at IS NULL
ORDER BY updated_at DESC;

-- name: CreateBlog :one
INSERT INTO projects.blogs (project_id, title, slug, content, status)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: UpdateBlog :one
UPDATE projects.blogs
SET
    title = $3,
    slug = $4,
    content = $5,
    status = $6,
    cover_image_url = $7,
    seo_title = $8,
    seo_description = $9,
    published_at = $10,
    updated_at = NOW()
WHERE id = $1
  AND project_id = $2
  AND deleted_at IS NULL
RETURNING *;

-- name: SoftDeleteBlog :exec
UPDATE projects.blogs
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND project_id = $2
  AND deleted_at IS NULL;

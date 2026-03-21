-- name: GetProjectByID :one
SELECT *
FROM projects.projects
WHERE id = $1
  AND deleted_at IS NULL;

-- name: GetProjectBySlug :one
SELECT *
FROM projects.projects
WHERE slug = $1
  AND deleted_at IS NULL;

-- name: ListProjectsByUserID :many
SELECT *
FROM projects.projects
WHERE user_id = $1
  AND deleted_at IS NULL
ORDER BY created_at DESC;

-- name: CreateProject :one
INSERT INTO projects.projects (user_id, name, slug)
VALUES ($1, $2, $3)
RETURNING *;

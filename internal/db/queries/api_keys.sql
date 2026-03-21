-- name: GetAPIKeyByHash :one
SELECT *
FROM projects.api_keys
WHERE key_hash = $1
  AND revoked_at IS NULL
  AND deleted_at IS NULL;

-- name: ListAPIKeysByProjectID :many
SELECT *
FROM projects.api_keys
WHERE project_id = $1
  AND deleted_at IS NULL
ORDER BY created_at DESC;

-- name: CreateAPIKey :one
INSERT INTO projects.api_keys (project_id, user_id, key_hash, label)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: RevokeAPIKey :exec
UPDATE projects.api_keys
SET revoked_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND project_id = $2
  AND revoked_at IS NULL
  AND deleted_at IS NULL;

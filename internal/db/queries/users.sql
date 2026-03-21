-- name: GetUserByEmail :one
SELECT *
FROM users.users
WHERE email = $1
  AND deleted_at IS NULL;

-- name: GetUserByID :one
SELECT *
FROM users.users
WHERE id = $1
  AND deleted_at IS NULL;

-- name: CreateUser :one
INSERT INTO users.users (email, password)
VALUES ($1, $2)
RETURNING *;

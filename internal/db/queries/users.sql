-- name: GetUserByEmail :one
SELECT * FROM users.users
WHERE email = $1 AND deleted_at IS NULL;

-- name: CreateUser :one
INSERT INTO users.users (email, password)
VALUES ($1, $2)
RETURNING *;

-- name: CreateOAuthAccount :one
INSERT INTO users.oauth_accounts (user_id, provider, provider_id)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetUserByOAuthProvider :one
SELECT u.* FROM users.users u
                    JOIN users.oauth_accounts oa ON u.id = oa.user_id
WHERE oa.provider = $1 AND oa.provider_id = $2 AND u.deleted_at IS NULL;

-- name: CreateVisitor :one
INSERT INTO projects.visitors (project_id, email, password, firstname, lastname)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: GetVisitorByEmail :one
SELECT * FROM projects.visitors
WHERE project_id = $1 AND email = $2 AND deleted_at IS NULL;
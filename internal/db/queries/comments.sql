-- name: ListCommentsByBlogID :many
SELECT *
FROM projects.comments
WHERE blog_id = $1
ORDER BY created_at ASC;

-- name: CreateComment :one
INSERT INTO projects.comments (blog_id, parent_id, visitor_id, body)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: DeleteComment :exec
DELETE FROM projects.comments
WHERE id = $1
  AND blog_id = $2;
-- name: CountLikesByBlogID :one
SELECT COUNT(*)::bigint AS count
FROM projects.likes
WHERE blog_id = $1;

-- name: CreateLike :one
INSERT INTO projects.likes (blog_id, visitor_id)
VALUES ($1, $2)
RETURNING *;

-- name: DeleteLike :exec
DELETE FROM projects.likes
WHERE blog_id = $1
  AND visitor_id = $2;
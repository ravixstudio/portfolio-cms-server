-- name: ListTagsByProjectID :many
SELECT *
FROM projects.tags
WHERE project_id = $1
ORDER BY name ASC;

-- name: GetTagByProjectAndSlug :one
SELECT *
FROM projects.tags
WHERE project_id = $1
  AND slug = $2;

-- name: UpsertTag :one
INSERT INTO projects.tags (project_id, name, slug)
VALUES ($1, $2, $3)
ON CONFLICT (project_id, slug) DO UPDATE
SET name = EXCLUDED.name
RETURNING *;

-- name: ListTagsForBlog :many
SELECT t.*
FROM projects.tags t
INNER JOIN projects.blog_tags bt ON bt.tag_id = t.id AND bt.project_id = t.project_id
WHERE bt.blog_id = $1
  AND bt.project_id = $2
ORDER BY t.name ASC;

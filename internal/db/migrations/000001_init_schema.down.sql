DROP TRIGGER IF EXISTS comments_parent_same_blog_trg ON projects.comments;
DROP FUNCTION IF EXISTS projects.enforce_comment_parent_same_blog();

DROP TABLE IF EXISTS projects.likes;
DROP TABLE IF EXISTS projects.comments;
DROP TABLE IF EXISTS projects.blog_tags;
DROP TABLE IF EXISTS projects.tags;
DROP TABLE IF EXISTS projects.blogs;
DROP TABLE IF EXISTS projects.api_keys;
DROP TABLE IF EXISTS projects.projects;
DROP TABLE IF EXISTS users.users;

DROP TYPE IF EXISTS projects.blog_status;

DROP SCHEMA IF EXISTS projects CASCADE;
DROP SCHEMA IF EXISTS users CASCADE;

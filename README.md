# Portfolio CMS — Product Overview

## What are we building?

A headless CMS platform specifically built for developers and designers who have personal portfolio websites and want to add a blog to it — without building a backend themselves.

The idea is simple: the user writes and manages their blog posts on **our platform**, and we give them **API endpoints** they can integrate into their own portfolio frontend (Next.js, Astro, Nuxt, plain HTML — whatever they use).

---

## The Problem

Developers who build portfolio sites often want a blog section. But setting up a database, building CRUD APIs, handling auth, and managing content is a lot of work for something secondary to the portfolio itself. Existing tools are either overkill (Strapi, WordPress) or lock you into their frontend (Medium, Hashnode).

There's no simple, managed backend service built specifically for portfolio-scale blogging.

---

## How it works

1. User signs up and creates a **Project** (representing their portfolio site).
2. They write and manage blog posts from our **dashboard**.
3. They generate an **API key** for their project.
4. They use that API key to call our public APIs from their portfolio frontend to fetch and display their posts.

That's it. We handle the backend, they own the frontend.

---

## Core Features

**Dashboard**

- Write blog posts in a Markdown editor
- Save posts as drafts or publish them
- Add tags, cover images, and SEO metadata to posts
- Manage API keys (create, label, revoke)
- Moderate comments (approve, reject, delete)
- See likes and comment counts per post

**Public API** _(consumed by the user's portfolio frontend)_

- Fetch all published posts (with pagination and tag filtering)
- Fetch a single post by slug
- Fetch comments on a post
- Submit a comment on a post
- Like / unlike a post

---

## Comments & Likes

Readers on the user's portfolio site can like posts and leave comments — all through our API. The blog owner moderates comments from the dashboard before they go public.

This means the portfolio owner never has to build any of this engagement infrastructure themselves.

---

## Future: Newsletter

Down the line, we want to support newsletters — letting readers subscribe to a blog, and letting the blog owner send email campaigns directly from the dashboard. The v1 architecture should keep this in mind so adding it later doesn't require major rework.

---

## Who is this for?

Primarily developers and designers who:

- Already have a portfolio site built on a frontend framework
- Want to add a blog without spinning up their own backend
- Want full control over how their blog looks (since they own the frontend)

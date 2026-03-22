# Requires: migrate CLI installed (brew install golang-migrate)
# Usage: make migrate-up
#        make migrate-down
#        make migrate-new NAME=add_indexes

MIGRATIONS_DIR := internal/db/migrations

# Load .env in a subshell-friendly way (adjust if your .env uses unsupported syntax)
define WITH_ENV
	bash -c 'set -euo pipefail; set -a; \
		[ -f .env ] && . ./.env; \
		set +a; \
		[ -n "$${DATABASE_URL:-}" ] || { echo "error: DATABASE_URL is empty (check .env)"; exit 1; }; \
		$(1)'
endef

.PHONY: migrate-up migrate-down migrate-down-one migrate-version migrate-create help

help:
	@echo "Targets:"
	@echo "  make migrate-up          - apply all pending migrations"
	@echo "  make migrate-down        - rollback one migration"
	@echo "  make migrate-down-one    - same as migrate-down"
	@echo "  make migrate-version     - print current migration version"
	@echo "  make migrate-create NAME=foo - create new up/down pair (seq)"

migrate-up:
	$(call WITH_ENV,migrate -path $(MIGRATIONS_DIR) -database "$$DATABASE_URL" up)

migrate-down migrate-down-one:
	$(call WITH_ENV,migrate -path $(MIGRATIONS_DIR) -database "$$DATABASE_URL" down 1)

migrate-version:
	$(call WITH_ENV,migrate -path $(MIGRATIONS_DIR) -database "$$DATABASE_URL" version)

migrate-create:
	@if [ -z "$(NAME)" ]; then echo "usage: make migrate-create NAME=your_migration_name"; exit 1; fi
	migrate create -ext sql -dir $(MIGRATIONS_DIR) -seq $(NAME)

start:
	go run ./cmd/server
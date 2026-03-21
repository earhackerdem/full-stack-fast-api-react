.DEFAULT_GOAL := help

COMPOSE_TEST := docker compose -f compose.yml -f compose.override.yml -f compose.test.yml

.PHONY: help setup dev up down clean logs test test-backend generate-client

help:
	@echo "Available commands:"
	@echo ""
	@echo "  make setup             Copy .env.example to .env and generate secrets"
	@echo "  make dev               Start the full stack with hot-reload (docker compose watch)"
	@echo "  make up                Start backend + mailcatcher for local frontend development"
	@echo "  make down              Stop all containers (preserves volumes)"
	@echo "  make clean             Stop all containers and remove volumes (destructive)"
	@echo "  make logs              Follow logs from all services"
	@echo "  make test              Run E2E tests via Playwright against isolated test database"
	@echo "  make test-backend      Run backend unit tests against isolated test database"
	@echo "  make generate-client   Regenerate the frontend API client from OpenAPI schema"

setup:
	@bash scripts/setup.sh

dev:
	docker compose watch

up:
	docker compose up -d --wait backend mailcatcher

down:
	docker compose down

clean:
	docker compose down -v

logs:
	docker compose logs -f

test:
	$(COMPOSE_TEST) up -d --wait backend-test mailcatcher
	$(COMPOSE_TEST) run --rm playwright bunx playwright test; \
	EXIT_CODE=$$?; \
	$(COMPOSE_TEST) down; \
	exit $$EXIT_CODE

test-backend:
	$(COMPOSE_TEST) up -d --wait backend-test
	$(COMPOSE_TEST) exec backend-test bash scripts/tests-start.sh; \
	EXIT_CODE=$$?; \
	$(COMPOSE_TEST) down; \
	exit $$EXIT_CODE

generate-client:
	bash scripts/generate-client.sh

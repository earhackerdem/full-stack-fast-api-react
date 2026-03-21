.DEFAULT_GOAL := help

.PHONY: help setup dev up down logs test test-backend generate-client

help:
	@echo "Available commands:"
	@echo ""
	@echo "  make setup             Copy .env.example to .env and generate secrets"
	@echo "  make dev               Start the full stack with hot-reload (docker compose watch)"
	@echo "  make up                Start backend + mailcatcher for local frontend development"
	@echo "  make down              Stop all containers and remove volumes"
	@echo "  make logs              Follow logs from all services"
	@echo "  make test              Run E2E tests via Playwright Docker container"
	@echo "  make test-backend      Run backend unit tests"
	@echo "  make generate-client   Regenerate the frontend API client from OpenAPI schema"

setup:
	@bash scripts/setup.sh

dev:
	docker compose watch

up:
	docker compose up -d --wait backend mailcatcher

down:
	docker compose down -v

logs:
	docker compose logs -f

test:
	docker compose up -d --wait backend mailcatcher
	docker compose run --rm playwright bunx playwright test

test-backend:
	docker compose up -d --wait backend
	docker compose exec backend bash scripts/tests-start.sh

generate-client:
	bash scripts/generate-client.sh

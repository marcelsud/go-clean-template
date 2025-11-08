.PHONY: help tests test-unit test-integration generate-mocks run-postgres stop-postgres cli-postgres migrate-up migrate-down benchmark ssh-machine-start ssh-machine-stop ssh-machine-connect ssh-machine-clean fly-machine-deploy fly-machine-console fly-machine-status fly-machine-logs fly-machine-destroy

help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║            Talk The Go Way - Make Targets                  ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Testing:"
	@echo "  make tests              - Run all tests (unit + integration)"
	@echo "  make test-unit          - Run only unit tests (fast)"
	@echo "  make test-integration   - Run only integration tests (slow, requires Docker)"
	@echo "  make benchmark          - Run benchmarks (requires Docker)"
	@echo ""
	@echo "Development:"
	@echo "  make run-postgres       - Start PostgreSQL container (Docker)"
	@echo "  make stop-postgres      - Stop PostgreSQL container"
	@echo "  make cli-postgres       - Run PostgreSQL CLI example"
	@echo ""
	@echo "Migrations:"
	@echo "  make migrate-up         - Apply database migrations"
	@echo "  make migrate-down       - Rollback database migrations"
	@echo ""
	@echo "SSH Docker Machine (Local):"
	@echo "  make ssh-machine-start  - Start SSH-enabled Docker machine"
	@echo "  make ssh-machine-stop   - Stop SSH-enabled Docker machine"
	@echo "  make ssh-machine-connect - Connect to SSH Docker machine"
	@echo "  make ssh-machine-clean  - Stop and remove SSH Docker machine"
	@echo ""
	@echo "Fly.io Machine (Remote):"
	@echo "  make fly-machine-deploy - Deploy Ubuntu+Docker machine to Fly.io"
	@echo "  make fly-machine-console - Connect via fly ssh console"
	@echo "  make fly-machine-status - Check machine status"
	@echo "  make fly-machine-logs   - View machine logs"
	@echo "  make fly-machine-destroy - Destroy Fly.io app and resources"
	@echo ""
	@echo "Other:"
	@echo "  make generate-mocks     - Generate mocks from interfaces"

# Testing targets
tests: generate-mocks
	@echo "Running all tests..."
	@go test ./... && go test -tags=integration ./...

test-unit: generate-mocks
	@echo "Running unit tests only..."
	@go test ./...

test-integration: generate-mocks
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker is not installed"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "❌ Docker is not running"; exit 1; }
	@echo "Running integration tests only (requires Docker)..."
	@go test -tags=integration ./...

benchmark: generate-mocks
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker is not installed"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "❌ Docker is not running"; exit 1; }
	@echo "Running benchmarks (requires Docker)..."
	@go test -tags=integration -bench=. -benchmem ./book/postgres/

generate-mocks:
	@go tool mockery --output book/mocks --dir book --all

# PostgreSQL Docker Compose targets
run-postgres:
	@echo "Starting PostgreSQL container..."
	@docker-compose up -d postgres
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 3
	@docker-compose exec postgres pg_isready -U postgres || true
	@echo "✅ PostgreSQL is ready!"

stop-postgres:
	@echo "Stopping PostgreSQL container..."
	@docker-compose down
	@echo "✅ PostgreSQL stopped!"

# CLI targets
cli-postgres:
	@echo "Running PostgreSQL CLI..."
	@go run cmd/cli-postgres/main.go

# Migration targets
migrate-up:
	@docker-compose ps postgres | grep -q " Up " || { echo "❌ PostgreSQL container is not running. Run 'make run-postgres' first"; exit 1; }
	@echo "Applying migrations..."
	@docker-compose exec -T postgres psql -U postgres -d books -f /docker-entrypoint-initdb.d/001_create_books_table.up.sql
	@echo "✅ Migrations applied!"

migrate-down:
	@docker-compose ps postgres | grep -q " Up " || { echo "❌ PostgreSQL container is not running. Run 'make run-postgres' first"; exit 1; }
	@echo "Reverting migrations..."
	@docker-compose exec -T postgres psql -U postgres -d books -f /docker-entrypoint-initdb.d/001_create_books_table.down.sql
	@echo "✅ Migrations reverted!"

# SSH Docker Machine targets
ssh-machine-start:
	@echo "Building and starting SSH Docker machine..."
	@docker-compose -f docker-compose.ssh-machine.yml up -d --build
	@echo "Waiting for SSH to be ready..."
	@sleep 5
	@echo "✅ SSH Docker machine is running!"
	@echo ""
	@echo "Connect using:"
	@echo "  ssh sshuser@localhost -p 2222"
	@echo "  Password: password"
	@echo ""
	@echo "Or run: make ssh-machine-connect"

ssh-machine-stop:
	@echo "Stopping SSH Docker machine..."
	@docker-compose -f docker-compose.ssh-machine.yml stop
	@echo "✅ SSH Docker machine stopped!"

ssh-machine-connect:
	@echo "Connecting to SSH Docker machine..."
	@echo "Password: password"
	@ssh -o StrictHostKeyChecking=no sshuser@localhost -p 2222

ssh-machine-clean:
	@echo "Stopping and removing SSH Docker machine..."
	@docker-compose -f docker-compose.ssh-machine.yml down -v
	@echo "✅ SSH Docker machine cleaned!"

# Fly.io Machine targets
FLY_APP_NAME ?= go-clean-template-ssh-machine
FLYCTL_INSTALL ?= /root/.fly
FLYCTL ?= $(FLYCTL_INSTALL)/bin/flyctl

fly-machine-deploy:
	@command -v $(FLYCTL) >/dev/null 2>&1 || { echo "❌ Fly.io CLI is not installed. Run the installer first."; exit 1; }
	@echo "Deploying Fly.io machine..."
	@if ! $(FLYCTL) status -a $(FLY_APP_NAME) >/dev/null 2>&1; then \
		echo "App does not exist. Creating..."; \
		$(FLYCTL) launch --now --name $(FLY_APP_NAME) --region mia --copy-config --yes; \
	else \
		echo "App exists. Deploying..."; \
		$(FLYCTL) deploy; \
	fi
	@echo "✅ Fly.io machine deployed!"
	@echo ""
	@echo "Connect using: make fly-machine-console"

fly-machine-console:
	@command -v $(FLYCTL) >/dev/null 2>&1 || { echo "❌ Fly.io CLI is not installed"; exit 1; }
	@echo "Connecting to Fly.io machine via SSH..."
	@$(FLYCTL) ssh console -a $(FLY_APP_NAME)

fly-machine-status:
	@command -v $(FLYCTL) >/dev/null 2>&1 || { echo "❌ Fly.io CLI is not installed"; exit 1; }
	@$(FLYCTL) status -a $(FLY_APP_NAME)

fly-machine-logs:
	@command -v $(FLYCTL) >/dev/null 2>&1 || { echo "❌ Fly.io CLI is not installed"; exit 1; }
	@$(FLYCTL) logs -a $(FLY_APP_NAME)

fly-machine-destroy:
	@command -v $(FLYCTL) >/dev/null 2>&1 || { echo "❌ Fly.io CLI is not installed"; exit 1; }
	@echo "⚠️  This will destroy the app and all resources!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || { echo "Cancelled."; exit 1; }
	@$(FLYCTL) apps destroy $(FLY_APP_NAME) --yes
	@echo "✅ Fly.io app destroyed!"
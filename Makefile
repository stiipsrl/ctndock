# Makefile for Docker Worktree Management
# Usage: make [command]

# Variables
COMPOSE_FILE = docker-compose.minimal.yml
COMPOSE = docker compose -f $(COMPOSE_FILE)
WORKSPACE_USER = laradock

# Default target
.DEFAULT_GOAL := help

# Help command
.PHONY: help
help: ## Show this help message
	@echo "Docker Worktree Management Commands"
	@echo "===================================="
	@echo ""
	@echo "Usage: make [command]"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make up        # Start containers"
	@echo "  make shell     # Enter workspace container"
	@echo "  make serve     # Start Laravel server"
	@echo "  make yarn-dev  # Start Vite dev server"

# Container Management
.PHONY: up
up: ## Start workspace container
	$(COMPOSE) up -d

.PHONY: down
down: ## Stop and remove containers
	$(COMPOSE) down

.PHONY: restart
restart: ## Restart all containers
	$(COMPOSE) restart

.PHONY: stop
stop: ## Stop containers without removing
	$(COMPOSE) stop

.PHONY: start
start: ## Start stopped containers
	$(COMPOSE) start

.PHONY: ps
ps: ## Show running containers
	$(COMPOSE) ps

.PHONY: build
build: ## Build or rebuild containers
	$(COMPOSE) build

.PHONY: rebuild
rebuild: ## Force rebuild containers
	$(COMPOSE) build --no-cache

# Container Access
.PHONY: shell
shell: ## Enter workspace container as laradock user
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace bash

.PHONY: root
root: ## Enter workspace container as root
	$(COMPOSE) exec workspace bash

# Logs
.PHONY: logs
logs: ## Show all container logs
	$(COMPOSE) logs -f

.PHONY: logs-workspace
logs-workspace: ## Show workspace logs
	$(COMPOSE) logs -f workspace

# Laravel Commands
.PHONY: artisan
artisan: ## Run artisan command (usage: make artisan cmd="migrate")
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan $(cmd)

.PHONY: serve
serve: ## Start Laravel development server
	@echo "Starting Laravel server on port 8002..."
	$(COMPOSE) exec -d --user=$(WORKSPACE_USER) workspace php artisan serve --host=0.0.0.0 --port=8000
	@sleep 2
	@echo "Laravel should be running on http://localhost:8002"

.PHONY: serve-stop
serve-stop: ## Stop Laravel development server
	@echo "Stopping Laravel server..."
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace bash -c "pkill -f 'artisan serve' || true"
	@echo "Laravel server stopped"

.PHONY: migrate
migrate: ## Run database migrations
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan migrate

.PHONY: seed
seed: ## Run database seeders
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan db:seed

.PHONY: fresh
fresh: ## Fresh migration with seeders
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan migrate:fresh --seed

.PHONY: tinker
tinker: ## Start Laravel tinker
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan tinker

.PHONY: queue
queue: ## Start queue worker
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan queue:work

.PHONY: cache-clear
cache-clear: ## Clear all Laravel caches
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan cache:clear
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan config:clear
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan route:clear
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan view:clear

# Composer Commands
.PHONY: composer
composer: ## Run composer command (usage: make composer cmd="install")
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace composer $(cmd)

.PHONY: composer-install
composer-install: ## Install composer dependencies
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace composer install

.PHONY: composer-update
composer-update: ## Update composer dependencies
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace composer update

.PHONY: composer-dump
composer-dump: ## Dump composer autoload
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace composer dump-autoload

# Yarn Commands
.PHONY: yarn
yarn: ## Run yarn command (usage: make yarn cmd="install")
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace yarn $(cmd)

.PHONY: yarn-install
yarn-install: ## Install yarn dependencies
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace yarn install

.PHONY: yarn-dev
yarn-dev: ## Start Vite development server
	@echo "Cleaning up old hot file..."
	@rm -f ../public/hot
	@echo "Starting Vite on port 5174..."
	$(COMPOSE) exec -d --user=$(WORKSPACE_USER) -e VITE_PORT=5174 workspace yarn dev
	@sleep 3
	@echo "Vite should be accessible on http://localhost:5174"

.PHONY: yarn-build
yarn-build: ## Build assets for production
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace yarn build

.PHONY: yarn-watch
yarn-watch: ## Watch for asset changes
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace yarn watch

.PHONY: yarn-stop
yarn-stop: ## Stop Vite development server
	@echo "Stopping Vite..."
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace bash -c "pkill -f 'vite' || true"
	@rm -f ../public/hot
	@echo "Vite stopped"

# Testing
.PHONY: test
test: ## Run all tests
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan test

.PHONY: test-parallel
test-parallel: ## Run tests in parallel
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan test --parallel

.PHONY: pest
pest: ## Run Pest tests
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace ./vendor/bin/pest

# Status Commands
.PHONY: status
status: ## Show container status and ports
	@echo "Container Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ctndock-develop || echo "No containers running"
	@echo ""
	@echo "Access URLs:"
	@echo "  Laravel (artisan serve): http://localhost:8002"
	@echo "  Vite:                    http://localhost:5174"
	@echo "  SSH:                     ssh laradock@localhost -p 2223"

.PHONY: ports
ports: ## Show port mappings
	@echo "Port Mappings for Develop Worktree:"
	@echo "====================================="
	@echo "Laravel:     8002 -> 8000"
	@echo "Vite:        5174 -> 5173"
	@echo "SSH:         2223 -> 22"

# Cleanup
.PHONY: clean
clean: ## Clean up containers and volumes
	$(COMPOSE) down -v

.PHONY: clean-orphans
clean-orphans: ## Remove orphan containers
	$(COMPOSE) up -d --remove-orphans

# Setup Commands
.PHONY: init
init: ## Initialize environment file from template
	@if [ ! -f .env ]; then \
		cp .env.dev .env; \
		echo "Created .env file from .env.dev"; \
		echo "Please review and adjust ports in .env file"; \
	else \
		echo ".env file already exists"; \
	fi

.PHONY: setup
setup: init build up ## Complete setup: init, build, and start containers
	@echo "Setup complete!"
	@echo "Run 'make shell' to enter the workspace"
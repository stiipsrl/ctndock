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
	@echo "  make artisan   # Run artisan commands"

# Container Management
.PHONY: up
up: ## Start workspace and nginx containers
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

.PHONY: logs-nginx
logs-nginx: ## Show nginx logs
	$(COMPOSE) logs -f nginx

# Laravel Commands
.PHONY: artisan
artisan: ## Run artisan command (usage: make artisan cmd="migrate")
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan $(cmd)

.PHONY: serve
serve: ## Start Laravel development server
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace php artisan serve --host=0.0.0.0 --port=8000

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

# NPM Commands
.PHONY: npm
npm: ## Run npm command (usage: make npm cmd="install")
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace npm $(cmd)

.PHONY: npm-install
npm-install: ## Install npm dependencies
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace npm install

.PHONY: npm-dev
npm-dev: ## Start Vite development server
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace npm run dev

.PHONY: npm-build
npm-build: ## Build assets for production
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace npm run build

.PHONY: npm-watch
npm-watch: ## Watch for asset changes
	$(COMPOSE) exec --user=$(WORKSPACE_USER) workspace npm run watch

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
	@echo "  Laravel (nginx):         http://localhost:8082"
	@echo "  Vite:                    http://localhost:5174"
	@echo "  SSH:                     ssh laradock@localhost -p 2223"

.PHONY: ports
ports: ## Show port mappings
	@echo "Port Mappings for Develop Worktree:"
	@echo "====================================="
	@echo "Laravel:     8002 -> 8000"
	@echo "Vite:        5174 -> 5173"
	@echo "SSH:         2223 -> 22"
	@echo "Nginx HTTP:  8082 -> 80"
	@echo "Nginx HTTPS: 8444 -> 443"

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
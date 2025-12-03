#--------------------------
# xebro GmbH - PHP - 1.0.2
#--------------------------

.PHONY:
DOCKER_PHP=${DOCKER_COMPOSE} run --rm php
DOCKER_RUN_WORKER=${DOCKER_COMPOSE} run --rm worker
SYMFONY_CONSOLE=${DOCKER_PHP} ./bin/console

PHP_DIR := $(patsubst $(XO_ROOT_DIR)/%,./%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PHP_DIR_ABS := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PHP := $(notdir $(patsubst %/,%,$(PHP_DIR)))

php.help:
	$(call add_help,${PHP_DIR}Makefile,"PHP")

php.logs: ## Show docker logs
	@${DOCKER_COMPOSE} logs -f php

worker.logs: ## Show docker logs
	@${DOCKER_COMPOSE} logs -f worker

php.bash: ## Open bash inside the container
	@${DOCKER_PHP} bash

worker.bash: ## Open bash inside the container
	@${DOCKER_RUN_WORKER} bash

php.cc: ## Clear the symfony cache
	$(call target_name,$@)
	@${SYMFONY_CONSOLE} c:c

php.db: ## Update database schema
	$(call target_name,$@)
	@${SYMFONY_CONSOLE} doctrine:schema:update --force

php.fixtures: ## Install all fixtures
	$(call target_name,$@)
	@${SYMFONY_CONSOLE} doctrine:fixtures:load --purge-with-truncate -n

php.migrate: ## Apply all migrations
	$(call target_name,$@)
	@${SYMFONY_CONSOLE} doctrine:migrations:migrate -n

php.migration: ## Create migration
	$(call target_name,$@)
	$(MAKE) stop
	$(MAKE) start
	$(MAKE) php.migrate
	@${SYMFONY_CONSOLE} make:migration -n
	$(MAKE) php.migrate
	$(MAKE) php.fixtures


php.test: ## Open bash inside the container
	$(call target_name,$@)
	@${DOCKER_PHP} ./bin/phpunit

php.composer.prod:
	@${DOCKER_PHP} composer install --no-ansi --no-dev --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader

php.composer.dev:
	@${DOCKER_PHP} composer install --no-ansi --no-interaction --no-progress

php.assets: ## Install assets
	$(call target_name,$@)
	@${SYMFONY_CONSOLE} assets:install

php.stan: ## Analyse php code
	$(call target_name,$@)
	@${DOCKER_PHP} ./vendor/bin/phpstan analyze -c phpstan.dist.neon --memory-limit=512M

php.lint:  ## Lint code
	$(call target_name,$@)
	@${DOCKER_PHP} ./vendor/bin/phplint src/
	@${SYMFONY_CONSOLE} lint:container
	@${SYMFONY_CONSOLE} lint:yaml --parse-tags config/
	@${SYMFONY_CONSOLE} lint:twig templates

php.cs-fixer: ## Cody style fix
	$(call target_name,$@)
	@${DOCKER_PHP} ./vendor/bin/php-cs-fixer fix

php.cs-check: ## Cody style validation
	$(call target_name,$@)
	@${DOCKER_PHP} ./vendor/bin/php-cs-fixer check

php.install:
	$(call headline,"Installing php")
	$(call ensure_env_vars,".env","${PHP_DIR}config/.env")

worker.docker.build: ## Build php container
	@${DOCKER_COMPOSE} build worker --no-cache

php.docker.build: ## Build php container
	@${DOCKER_COMPOSE} build php --no-cache

php.restart: php.migrate php.fixtures ## Restart PHP
	$(call target_name,$@)
	@${DOCKER_COMPOSE} restart php --no-deps
	@${DOCKER_COMPOSE} restart worker --no-deps

worker.restart:
	$(call target_name,$@)
	@${DOCKER_COMPOSE} restart worker --no-deps

php.exec:
	${DOCKER_PHP} bash -c $${cmd}

php.cmd:
	${SYMFONY_CONSOLE} $${cmd}

php.validate_db:
	$(call target_name,$@)
	@${SYMFONY_CONSOLE} doctrine:schema:validate

php.jwt_keys:
	@${SYMFONY_CONSOLE} lexik:jwt:generate-keypair --skip-if-exists

php.debug: ## Print PHP component environment
	@$(call headline,"DEBUGGING PHP")
	@printf "${Purple}PHP: ${Yellow} ${PHP}\n"
	@printf "${Purple}PHP_DIR: ${Yellow} ${PHP_DIR}\n"

ci: php.cs-fixer php.stan php.lint php.validate_db php.test
debug: php.debug
fix: php.cs-fixer php.stan
help: php.help
init: php.install php.composer.dev php.migrate php.fixtures php.cc
install: php.install
lint: php.lint php.validate_db
php.verify: php.cs-fixer php.stan php.lint php.validate_db php.test ## Run CS fix, static analysis, lint, DB validate, tests
restart: php.restart
test: php.test

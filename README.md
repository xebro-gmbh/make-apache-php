# PHP Docker — Make Targets

This directory contains Make targets to work with the PHP/Symfony application inside the `php` Docker service defined in `compose.yaml`.

Run targets from the repository context where `DOCKER_COMPOSE` is defined (typically the project root), or from this folder if your environment already exports it.

## Usage

- List PHP-related help: `make php.help`
- Run a target: `make <target>` (for example, `make php.bash`)
- Pass a Symfony command: `make php.cmd cmd='about'`

## Targets

Runtime / Container
- `php.docker.build` — Build the PHP container image (no cache).
- `php.logs` — Follow logs of the `php` service container.
- `php.bash` — Open an interactive Bash shell in the container.
- `php.restart` — Run DB migrations and fixtures, then restart the `php` service.
- `restart` — Alias for `php.restart`.
- `help` — Alias for `php.help`.

Application Lifecycle
- `php.install` — Project setup; adds required config (e.g., copies `.env` if missing).
- `install` — Alias for `php.install`.
- `init` — Dev init: composer install (dev), run migrations, load fixtures, generate JWT keys, clear cache.
- `php.assets` — Install Symfony assets.
- `php.cmd` — Run a Symfony console command, e.g. `make php.cmd cmd='cache:clear'`.
- `php.cc` — Clear the Symfony cache.
- `php.jwt_keys` — Generate JWT key pair (skips if it already exists).

Database
- `php.db` — Update Doctrine schema in place (`doctrine:schema:update --force`).
- `php.migrate` — Apply all Doctrine migrations (non-interactive).
- `php.migration` — Create a new Doctrine migration class.
- `php.fixtures` — Load all fixtures, purging data with truncate (destructive).
- `php.validate_db` — Validate that the Doctrine mapping matches the database schema.

Composer
- `php.composer.dev` — Install Composer deps with dev packages.
- `php.composer.prod` — Install Composer deps optimized for production (no dev/plugins/scripts, optimized autoloader).

Quality / CI
- `php.lint` — Lint PHP (`phplint`), container, YAML, and Twig files.
- `php.stan` — Static analysis with PHPStan.
- `php.cs-fixer` — Apply code style fixes with PHP-CS-Fixer.
- `fix` — Run `php.cs-fixer` and `php.stan`.
- `lint` — Run `php.lint` and `php.validate_db`.
- `ci` — Run formatter, static analysis, linters, DB validation, and tests.

Tests
- `php.test` — Run PHPUnit test suite inside the container.
- `test` — Alias for `php.test`.

## Notes

- Some targets modify code or data:
  - `php.fixtures` truncates tables before loading fixtures (destructive).
  - `php.db` changes the schema directly; prefer migrations for production.
  - `php.cs-fixer` rewrites files to apply code style fixes.
- Environment variables like `XO_ROOT_DIR`, `XO_PHP_ROOT`, and the `DOCKER_COMPOSE` command are expected to be provided by the parent Makefile or your shell environment.

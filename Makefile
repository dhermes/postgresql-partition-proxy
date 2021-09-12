.PHONY: help
help:
	@echo 'Makefile for `postgresql-partition-proxy` experiment'
	@echo ''
	@echo 'Usage:'
	@echo '   make clean                   Forcefully remove all generated artifacts (e.g. Terraform state files)'
	@echo '   make shellcheck              Run `shellcheck` on all shell files in `./_bin/`'
	@echo 'Terraform-specific Targets:'
	@echo '   make start-containers        Start PostgreSQL Docker containers.'
	@echo '   make stop-containers         Stop PostgreSQL Docker containers.'
	@echo '   make initialize-databases    Initialize the database, schema, roles and grants in the PostgreSQL instances'
	@echo '   make teardown-databases      Teardown the database, schema, roles and grants in the PostgreSQL instances'
	@echo 'Development Database-specific Targets:'
	@echo '   make psql-veneer             Connects to currently running Veneer PostgreSQL DB via `psql` as app user'
	@echo '   make psql-shard1             Connects to currently running Bluth Co PostgreSQL DB via `psql` as app user'
	@echo '   make psql-shard2             Connects to currently running Cyberdyne PostgreSQL DB via `psql` as app user'
	@echo '   make psql-shard3             Connects to currently running Initech PostgreSQL DB via `psql` as app user'
	@echo '   make migrations              Runs database schema migrations in all PostgreSQL DB instances'
	@echo '   make show-logs-veneer        Show log of all statements in Veneer PostgreSQL DB since starting.'
	@echo '   make show-logs-shard1        Show log of all statements in Bluth Co PostgreSQL DB since starting.'
	@echo '   make show-logs-shard2        Show log of all statements in Cyberdyne PostgreSQL DB since starting.'
	@echo '   make show-logs-shard3        Show log of all statements in Initech PostgreSQL DB since starting.'
	@echo ''

################################################################################
# Meta-variables
################################################################################
SHELLCHECK_PRESENT := $(shell command -v shellcheck 2> /dev/null)
PSQL_PRESENT := $(shell command -v psql 2> /dev/null)

################################################################################
# Generic Targets
################################################################################

.PHONY: clean
clean:
	rm -f \
	  terraform/workspaces/databases/.terraform.lock.hcl \
	  terraform/workspaces/databases/terraform.tfstate \
	  terraform/workspaces/databases/terraform.tfstate.backup \
	  terraform/workspaces/docker/.terraform.lock.hcl \
	  terraform/workspaces/docker/terraform.tfstate \
	  terraform/workspaces/docker/terraform.tfstate.backup
	rm -fr \
	  terraform/workspaces/databases/.terraform/ \
	  terraform/workspaces/docker/.terraform/
	docker rm --force \
	  dev-postgres-shard1 \
	  dev-postgres-shard2 \
	  dev-postgres-shard3 \
	  dev-postgres-veneer
	docker network rm dev-network-ppp || true

.PHONY: shellcheck
shellcheck: _require-shellcheck
	shellcheck --exclude SC1090,SC1091 ./_bin/*.sh

################################################################################
# Terraform-specific Targets
################################################################################

.PHONY: start-containers
start-containers:
	@cd terraform/workspaces/docker/ && \
	  terraform init && \
	  terraform apply --auto-approve

.PHONY: stop-containers
stop-containers:
	@cd terraform/workspaces/docker/ && \
	  terraform init && \
	  terraform apply --destroy --auto-approve

.PHONY: initialize-databases
initialize-databases:
	@cd terraform/workspaces/databases/ && \
	  terraform init && \
	  terraform apply --auto-approve

.PHONY: teardown-databases
teardown-databases:
	@cd terraform/workspaces/databases/ && \
	  terraform init && \
	  terraform apply --destroy --auto-approve

################################################################################
# Development Database-specific Targets
################################################################################

.PHONY: psql-veneer
psql-veneer: _require-psql
	psql "postgres://veneer_app:1234abcd@localhost:14797/veneer"

.PHONY: psql-shard1
psql-shard1: _require-psql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_app:5678efgh@localhost:29948/bluth_co"

.PHONY: psql-shard2
psql-shard2: _require-psql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_app:9012ijkl@localhost:13366/cyberdyne"

.PHONY: psql-shard3
psql-shard3: _require-psql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_app:3456mnop@localhost:11033/initech"

.PHONY: _migrations-shard1
_migrations-shard1: _require-psql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_admin:efgh5678@localhost:29948/bluth_co" --file ./migrations/0001-create-authors-table.sql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_admin:efgh5678@localhost:29948/bluth_co" --file ./migrations/0002-create-books-table.sql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_admin:efgh5678@localhost:29948/bluth_co" --file ./migrations/0003-seed-tables.sql

.PHONY: _migrations-shard2
_migrations-shard2: _require-psql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_admin:ijkl9012@localhost:13366/cyberdyne" --file ./migrations/0001-create-authors-table.sql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_admin:ijkl9012@localhost:13366/cyberdyne" --file ./migrations/0002-create-books-table.sql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_admin:ijkl9012@localhost:13366/cyberdyne" --file ./migrations/0003-seed-tables.sql

.PHONY: _migrations-shard3
_migrations-shard3: _require-psql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_admin:mnop3456@localhost:11033/initech" --file ./migrations/0001-create-authors-table.sql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_admin:mnop3456@localhost:11033/initech" --file ./migrations/0002-create-books-table.sql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_admin:mnop3456@localhost:11033/initech" --file ./migrations/0003-seed-tables.sql

.PHONY: _migrations-veneer
_migrations-veneer: _require-psql
	psql "postgres://veneer_admin:abcd1234@localhost:14797/veneer" --file ./migrations/fdw-0001-map-shard1.sql
	psql "postgres://veneer_admin:abcd1234@localhost:14797/veneer" --file ./migrations/fdw-0002-map-shard2.sql
	psql "postgres://veneer_admin:abcd1234@localhost:14797/veneer" --file ./migrations/fdw-0003-map-shard3.sql

.PHONY: migrations
migrations: _migrations-shard1 _migrations-shard2 _migrations-shard3 _migrations-veneer

.PHONY: show-logs-veneer
show-logs-veneer:
	@DB_CONTAINER_NAME=dev-postgres-veneer ./_bin/show-db-logs.sh

.PHONY: show-logs-shard1
show-logs-shard1:
	@DB_CONTAINER_NAME=dev-postgres-shard1 ./_bin/show-db-logs.sh

.PHONY: show-logs-shard2
show-logs-shard2:
	@DB_CONTAINER_NAME=dev-postgres-shard2 ./_bin/show-db-logs.sh

.PHONY: show-logs-shard3
show-logs-shard3:
	@DB_CONTAINER_NAME=dev-postgres-shard3 ./_bin/show-db-logs.sh

################################################################################
# Internal / Doctor Targets
################################################################################

.PHONY: _require-shellcheck
_require-shellcheck:
ifndef SHELLCHECK_PRESENT
	$(error 'shellcheck is not installed, it can be installed via "apt-get install shellcheck" or "brew install shellcheck".')
endif

.PHONY: _require-psql
_require-psql:
ifndef PSQL_PRESENT
	$(error 'psql is not installed, it can be installed via "brew install postgresql" or "apt-get install postgresql".')
endif

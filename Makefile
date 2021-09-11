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
	@echo '   make psql-bluth-co           Connects to currently running Bluth Co PostgreSQL DB via `psql` as app user'
	@echo '   make psql-cyberdyne          Connects to currently running Cyberdyne PostgreSQL DB via `psql` as app user'
	@echo '   make psql-initech            Connects to currently running Initech PostgreSQL DB via `psql` as app user'
	@echo '   make migrations              Runs database schema migrations in all PostgreSQL DB instances'
	@echo '   make show-logs-veneer        Show log of all statements in Veneer PostgreSQL DB since starting.'
	@echo '   make show-logs-bluth-co      Show log of all statements in Bluth Co PostgreSQL DB since starting.'
	@echo '   make show-logs-cyberdyne     Show log of all statements in Cyberdyne PostgreSQL DB since starting.'
	@echo '   make show-logs-initech       Show log of all statements in Initech PostgreSQL DB since starting.'
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

.PHONY: psql-bluth-co
psql-bluth-co: _require-psql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_app:5678efgh@localhost:29948/bluth_co"

.PHONY: psql-cyberdyne
psql-cyberdyne: _require-psql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_app:9012ijkl@localhost:13366/cyberdyne"

.PHONY: psql-initech
psql-initech: _require-psql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_app:3456mnop@localhost:11033/initech"

.PHONY: _migrations-bluth-co
_migrations-bluth-co: _require-psql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_admin:efgh5678@localhost:29948/bluth_co" --file ./migrations/0001_create_authors_table.sql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_admin:efgh5678@localhost:29948/bluth_co" --file ./migrations/0002_create_books_table.sql
	PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_admin:efgh5678@localhost:29948/bluth_co" --file ./migrations/0003_seed_tables.sql

.PHONY: _migrations-cyberdyne
_migrations-cyberdyne: _require-psql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_admin:ijkl9012@localhost:13366/cyberdyne" --file ./migrations/0001_create_authors_table.sql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_admin:ijkl9012@localhost:13366/cyberdyne" --file ./migrations/0002_create_books_table.sql
	PGOPTIONS="-c search_path=cyberdyne" psql "postgres://cyberdyne_admin:ijkl9012@localhost:13366/cyberdyne" --file ./migrations/0003_seed_tables.sql

.PHONY: _migrations-initech
_migrations-initech: _require-psql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_admin:mnop3456@localhost:11033/initech" --file ./migrations/0001_create_authors_table.sql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_admin:mnop3456@localhost:11033/initech" --file ./migrations/0002_create_books_table.sql
	PGOPTIONS="-c search_path=initech" psql "postgres://initech_admin:mnop3456@localhost:11033/initech" --file ./migrations/0003_seed_tables.sql

.PHONY: _migrations-veneer
_migrations-veneer: _require-psql
	psql "postgres://veneer_admin:abcd1234@localhost:14797/veneer" --file ./migrations/fdw_0001_map_bluth_co.sql
	psql "postgres://veneer_admin:abcd1234@localhost:14797/veneer" --file ./migrations/fdw_0002_map_cyberdyne.sql
	psql "postgres://veneer_admin:abcd1234@localhost:14797/veneer" --file ./migrations/fdw_0003_map_initech.sql

.PHONY: migrations
migrations: _migrations-bluth-co _migrations-cyberdyne _migrations-initech _migrations-veneer

.PHONY: show-logs-veneer
show-logs-veneer:
	@DB_CONTAINER_NAME=dev-postgres-veneer ./_bin/show_db_logs.sh

.PHONY: show-logs-bluth-co
show-logs-bluth-co:
	@DB_CONTAINER_NAME=dev-postgres-bluth-co ./_bin/show_db_logs.sh

.PHONY: show-logs-cyberdyne
show-logs-cyberdyne:
	@DB_CONTAINER_NAME=dev-postgres-cyberdyne ./_bin/show_db_logs.sh

.PHONY: show-logs-initech
show-logs-initech:
	@DB_CONTAINER_NAME=dev-postgres-initech ./_bin/show_db_logs.sh

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

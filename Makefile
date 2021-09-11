.PHONY: help
help:
	@echo 'Makefile for `postgresql-partition-proxy` experiment'
	@echo ''
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
	@echo ''

################################################################################
# Meta-variables
################################################################################
PSQL_PRESENT := $(shell command -v psql 2> /dev/null)

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
	psql "postgres://bluth_co_app:5678efgh@localhost:29948/bluth_co"

.PHONY: psql-cyberdyne
psql-cyberdyne: _require-psql
	psql "postgres://cyberdyne_app:9012ijkl@localhost:13366/cyberdyne"

.PHONY: psql-initech
psql-initech: _require-psql
	psql "postgres://initech_app:3456mnop@localhost:11033/initech"

################################################################################
# Internal / Doctor Targets
################################################################################

.PHONY: _require-psql
_require-psql:
ifndef PSQL_PRESENT
	$(error 'psql is not installed, it can be installed via "brew install postgresql" or "apt-get install postgresql".')
endif

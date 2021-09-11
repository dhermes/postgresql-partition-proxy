.PHONY: help
help:
	@echo 'Makefile for `postgresql-partition-proxy` experiment'
	@echo ''
	@echo 'Terraform-specific Targets:'
	@echo '   make start-containers    Start PostgreSQL Docker containers.'
	@echo '   make stop-containers     Stop PostgreSQL Docker containers.'
	@echo ''

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

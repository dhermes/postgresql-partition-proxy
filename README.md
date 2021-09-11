# PPP: PostgreSQL Partition Proxy

This is an attempt to show a small proof of concept where a single
PostgreSQL can be used as a c into multiple distinct physical
shards. The use case is multitenant systems where the data can easily
be sharded by tenant. Using PostgreSQL foreign data wrappers, we can

- Map a tenant onto a PostgreSQL schema in a straightforward way
- Home the data for the tenant / schema on a single physical shard
- Use the pass through PostgreSQL instance to relay queries to the
  physical shard

## Development

```
$ make  # Or `make help`
Makefile for `postgresql-partition-proxy` experiment

Terraform-specific Targets:
   make start-containers    Start PostgreSQL Docker containers.
   make stop-containers     Stop PostgreSQL Docker containers.

```

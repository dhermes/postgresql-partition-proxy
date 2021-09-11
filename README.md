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

Usage:
   make vet                          Run `go vet` over project source tree
   make shellcheck                   Run `shellcheck` on all shell files in `./_bin/`
Terraform-specific Targets:
   make start-containers        Start PostgreSQL Docker containers.
   make stop-containers         Stop PostgreSQL Docker containers.
   make initialize-databases    Initialize the database, schema, roles and grants in the PostgreSQL instances
   make teardown-databases      Teardown the database, schema, roles and grants in the PostgreSQL instances
Development Database-specific Targets:
   make psql-veneer             Connects to currently running Veneer PostgreSQL DB via `psql` as app user
   make psql-bluth-co           Connects to currently running Bluth Co PostgreSQL DB via `psql` as app user
   make psql-cyberdyne          Connects to currently running Cyberdyne PostgreSQL DB via `psql` as app user
   make psql-initech            Connects to currently running Initech PostgreSQL DB via `psql` as app user
   make migrations              Runs database schema migrations in all PostgreSQL DB instances

```

## Resources

-   PostgreSQL's Foreign Data Wrapper [post][1] from thoughtbot

[1]: https://thoughtbot.com/blog/postgres-foreign-data-wrapper

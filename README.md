# PPP: PostgreSQL Partition Proxy

This is an attempt to show a small proof of concept where a single
PostgreSQL instance can be used as a pass through into multiple distinct 
physical shards. The use case is multitenant systems where the data can 
easily be sharded by tenant. Using PostgreSQL foreign data wrappers, we can

- Map a tenant onto a PostgreSQL schema in a straightforward way
- Home the data for the tenant / schema on a single physical shard
- Use the pass through PostgreSQL instance to relay queries to the
  physical shard

Check out [IN_ACTION.md][2] to see the PostgreSQL Partition Proxy in action.
In particular, we'll dive into setting up the physical shards and explore the
behavior of queries that get forwarded from the proxy instance to a given
shard.

## Development

```
$ make  # Or `make help`
Makefile for `postgresql-partition-proxy` experiment

Usage:
   make clean                   Forcefully remove all generated artifacts (e.g. Terraform state files)
   make shellcheck              Run `shellcheck` on all shell files in `./_bin/`
Terraform-specific Targets:
   make start-containers        Start PostgreSQL Docker containers.
   make stop-containers         Stop PostgreSQL Docker containers.
   make initialize-databases    Initialize the database, schema, roles and grants in the PostgreSQL instances
   make teardown-databases      Teardown the database, schema, roles and grants in the PostgreSQL instances
Development Database-specific Targets:
   make psql-veneer             Connects to currently running Veneer PostgreSQL DB via `psql` as app user
   make psql-veneer-admin       Connects to currently running Veneer PostgreSQL DB via `psql` as admin user
   make psql-shard1             Connects to currently running Bluth Co PostgreSQL DB via `psql` as app user
   make psql-shard2             Connects to currently running Cyberdyne PostgreSQL DB via `psql` as app user
   make psql-shard3             Connects to currently running Initech PostgreSQL DB via `psql` as app user
   make migrations              Runs database schema migrations in all PostgreSQL DB instances
   make show-logs-veneer        Show log of all statements in Veneer PostgreSQL DB since starting.
   make show-logs-shard1        Show log of all statements in Bluth Co PostgreSQL DB since starting.
   make show-logs-shard2        Show log of all statements in Cyberdyne PostgreSQL DB since starting.
   make show-logs-shard3        Show log of all statements in Initech PostgreSQL DB since starting.

```

## Resources

-   PostgreSQL's Foreign Data Wrapper [post][1] from thoughtbot
-   Foreign Data Wrappers in PostgreSQL and a closer look at `postgres_fdw`
    [post][3] from Percona

[1]: https://thoughtbot.com/blog/postgres-foreign-data-wrapper
[2]: IN_ACTION.md
[3]: https://www.percona.com/blog/2018/08/21/foreign-data-wrappers-postgresql-postgres_fdw/

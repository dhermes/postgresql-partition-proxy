# PPP: PostgreSQL Partition Proxy

This is an attempt to show a small proof of concept where a single
PostgreSQL can be used as a pass through into multiple distinct physical
shards. The use case is multitenant systems where the data can easily
be sharded by tenant. Using PostgreSQL foreign data wrappers, we can

- Map a tenant onto a PostgreSQL schema in a straightforward way
- Home the data for the tenant / schema on a single physical shard
- Use the pass through PostgreSQL instance to relay queries to the
  physical shard

## In Action

First, start up the three "physical" shards (`bluth_co`, `cyberdyne` and
`initech`) as well as the pass through (`veneer`):

```
$ make start-containers
...
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
$
$ docker ps
CONTAINER ID   IMAGE                      COMMAND                  CREATED              STATUS              PORTS                     NAMES
997480aa097e   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:14797->5432/tcp   dev-postgres-veneer
0c94aa5e83b0   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:29948->5432/tcp   dev-postgres-bluth-co
ddb93e29b7af   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:13366->5432/tcp   dev-postgres-cyberdyne
0d047aded5a6   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:11033->5432/tcp   dev-postgres-initech
```

Then actually create `{db}_admin` and `{db}_app` users in each PostgreSQL
instance:

```
$ make initialize-databases
...
Apply complete! Resources: 60 added, 0 changed, 0 destroyed.
$
$ make psql-bluth-co
PGOPTIONS="-c search_path=bluth_co" psql "postgres://bluth_co_app:5678efgh@localhost:29948/bluth_co"
psql (13.4, server 13.3)
Type "help" for help.

bluth_co=> \dn
      List of schemas
   Name   |     Owner
----------+----------------
 bluth_co | bluth_co_admin
 public   | superuser
(2 rows)

bluth_co=>  \q
```

Finally, run the **data** migrations in the "physical" shards and run
DDL (migrations) to set up the foreign data wrapper in `veneer`:

```
$ make migrations
...
COMMIT
```

After doing this, we can directly query foreign tables in the `veneer`
database from a single connection:

```
$ make psql-veneer
psql "postgres://veneer_app:1234abcd@localhost:14797/veneer"
psql (13.4, server 13.3)
Type "help" for help.

veneer=> SELECT * FROM bluth_co.authors WHERE first_name = 'Ernest';
                  id                  | first_name | last_name
--------------------------------------+------------+-----------
 8912c6c5-9c90-4df9-8e99-01239bcf8505 | Ernest     | Hemingway
(1 row)

veneer=> SELECT * FROM cyberdyne.authors WHERE first_name = 'Ernest';
                  id                  | first_name | last_name
--------------------------------------+------------+-----------
 a9323af4-09b6-482f-87ec-54ddc4335cfc | Ernest     | Hemingway
(1 row)

veneer=> SELECT * FROM initech.authors WHERE first_name = 'Ernest';
                  id                  | first_name | last_name
--------------------------------------+------------+-----------
 1ab14132-c706-4094-aaac-fe4d870e888d | Ernest     | Hemingway
(1 row)
```

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
   make show-logs-veneer        Show log of all statements in Veneer PostgreSQL DB since starting.
   make show-logs-bluth-co      Show log of all statements in Bluth Co PostgreSQL DB since starting.
   make show-logs-cyberdyne     Show log of all statements in Cyberdyne PostgreSQL DB since starting.
   make show-logs-initech       Show log of all statements in Initech PostgreSQL DB since starting.

```

## Resources

-   PostgreSQL's Foreign Data Wrapper [post][1] from thoughtbot

[1]: https://thoughtbot.com/blog/postgres-foreign-data-wrapper

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

## Checking in on Performance

In previous versions of PostgreSQL, a `JOIN` between two foreign tables
would be an expensive operation: the two tables would be streamed onto the
server from the remotes and joined there.

In order to ensure this doesn't happen **within the same schema** we can
check the query log to see which queries are run (and where). Before doing
a `JOIN`, we mark a logs checkpoint:

```
$ make show-logs-veneer
...
2021-09-11 07:25:05.485 UTC 613c59d1.f7 u:(veneer_admin) d:(veneer) LOG:  statement: COMMIT;
$
$ make show-logs-bluth-co
...
2021-09-11 07:25:05.240 UTC 613c59d1.99 u:(bluth_co_admin) d:(bluth_co) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-cyberdyne
...
2021-09-11 07:25:05.366 UTC 613c59d1.98 u:(cyberdyne_admin) d:(cyberdyne) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-initech
...
2021-09-11 07:25:05.486 UTC 613c59d1.96 u:(initech_admin) d:(initech) LOG:  statement: COMMIT TRANSACTION
```

Now, we issue a `JOIN` query against two tables in the same physical
shard:

```
$ make psql-veneer
psql "postgres://veneer_app:1234abcd@localhost:14797/veneer"
psql (13.4, server 13.3)
Type "help" for help.

veneer=> SELECT
veneer->   a.id AS author_id,
veneer->   b.id AS book_id,
veneer->   a.first_name AS author_first_name,
veneer->   a.last_name AS author_last_name,
veneer->   b.title AS title,
veneer->   b.publish_date AS publish_date
veneer-> FROM
veneer->   bluth_co.authors AS a
veneer-> INNER JOIN
veneer->   bluth_co.books AS b
veneer-> ON
veneer->   a.id = b.author_id
veneer-> WHERE
veneer->   a.last_name = 'Rice';
              author_id               |               book_id                | author_first_name | author_last_name |           title            | publish_date
--------------------------------------+--------------------------------------+-------------------+------------------+----------------------------+--------------
 d1539cff-2177-4fc4-b3f8-67b55a1f977b | 6886cfeb-fec7-403c-86f7-e1daa36fdb63 | Anne              | Rice             | The Wolf Gift              | 2012-02-14
 d1539cff-2177-4fc4-b3f8-67b55a1f977b | 4f12a7e7-72ec-41e3-a7f2-09e98ca1e51f | Anne              | Rice             | Interview with the Vampire | 1976-05-05
 d1539cff-2177-4fc4-b3f8-67b55a1f977b | 0af9b38c-0a4f-4720-b36d-2ec1d27b44e3 | Anne              | Rice             | The Queen of the Damned    | 1988-09-12
(3 rows)

veneer=> \q
```

We can then check back in, first on the shards we didn't touch:

```
$ make show-logs-cyberdyne
...
2021-09-11 07:25:05.366 UTC 613c59d1.98 u:(cyberdyne_admin) d:(cyberdyne) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-initech
...
2021-09-11 07:25:05.486 UTC 613c59d1.96 u:(initech_admin) d:(initech) LOG:  statement: COMMIT TRANSACTION
```

and then on the two we did:

```
$ make show-logs-veneer
...
2021-09-11 07:25:05.485 UTC 613c59d1.f7 u:(veneer_admin) d:(veneer) LOG:  statement: COMMIT;
2021-09-11 07:37:33.741 UTC 613c5bec.12f u:(veneer_app) d:(veneer) LOG:  statement: SELECT
          a.id AS author_id,
          b.id AS book_id,
          a.first_name AS author_first_name,
          a.last_name AS author_last_name,
          b.title AS title,
          b.publish_date AS publish_date
        FROM
          bluth_co.authors AS a
        INNER JOIN
          bluth_co.books AS b
        ON
          a.id = b.author_id
        WHERE
          a.last_name = 'Rice';
$
$ make show-logs-bluth-co
...
2021-09-11 07:25:05.240 UTC 613c59d1.99 u:(bluth_co_admin) d:(bluth_co) LOG:  statement: COMMIT TRANSACTION
2021-09-11 07:37:33.767 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: SET search_path = pg_catalog
2021-09-11 07:37:33.770 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: SET timezone = 'UTC'
2021-09-11 07:37:33.773 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: SET datestyle = ISO
2021-09-11 07:37:33.776 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: SET intervalstyle = postgres
2021-09-11 07:37:33.779 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: SET extra_float_digits = 3
2021-09-11 07:37:33.781 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-11 07:37:33.785 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  execute <unnamed>: DECLARE c1 CURSOR FOR
        SELECT r1.id, r2.id, r1.first_name, r1.last_name, r2.title, r2.publish_date FROM (bluth_co.authors r1 INNER JOIN bluth_co.books r2 ON (((r1.id = r2.author_id)) AND ((r1.last_name = 'Rice'::text))))
2021-09-11 07:37:33.788 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: FETCH 100 FROM c1
2021-09-11 07:37:33.791 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: CLOSE c1
2021-09-11 07:37:33.793 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: COMMIT TRANSACTION
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

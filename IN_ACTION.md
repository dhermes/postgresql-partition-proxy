# PostgreSQL Partition Proxy in Action

## Initialize PostgreSQL Instances

First, start up the three "physical" shards with four distinct tenants
(`bluth_co`, `cyberdyne`, `dunder_mifflin` and `initech`) as well as the pass
through (`veneer`):

```
$ make start-containers
...
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
$
$ docker ps
CONTAINER ID   IMAGE                      COMMAND                  CREATED          STATUS          PORTS                     NAMES
2c4877b60a6e   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   11 seconds ago   Up 9 seconds    0.0.0.0:29948->5432/tcp   dev-postgres-shard1
f18a809da222   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   11 seconds ago   Up 10 seconds   0.0.0.0:13366->5432/tcp   dev-postgres-shard2
55c24efd29b4   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   11 seconds ago   Up 10 seconds   0.0.0.0:11033->5432/tcp   dev-postgres-shard3
01fb340eff73   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   11 seconds ago   Up 10 seconds   0.0.0.0:14797->5432/tcp   dev-postgres-veneer
```

Then actually create `bookstore_admin` and `bookstore_app` users in each
PostgreSQL instance:

```
$ make initialize-databases
...
Apply complete! Resources: 74 added, 0 changed, 0 destroyed.
$
$ make psql-shard1
psql "postgres://bookstore_app:5678efgh@localhost:29948/bookstore"
psql (13.4, server 13.3)
Type "help" for help.

bookstore=> \dn
      List of schemas
   Name   |      Owner
----------+-----------------
 bluth_co | bookstore_admin
 public   | superuser
(2 rows)

bookstore=> \q
```

## Simulation Application Lifecyle: Migrations

Run the **data** migrations in the "physical" shards and run
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

veneer=> SELECT pg_backend_pid(), * FROM bluth_co.authors WHERE first_name = 'Ernest';
 pg_backend_pid |                  id                  | first_name | last_name
----------------+--------------------------------------+------------+-----------
            145 | 88073cf8-102c-4f6d-b1cf-8bfc809b951d | Ernest     | Hemingway
(1 row)

veneer=> SELECT pg_backend_pid(), * FROM cyberdyne.authors WHERE first_name = 'Ernest';
 pg_backend_pid |                  id                  | first_name | last_name
----------------+--------------------------------------+------------+-----------
            145 | 1b20af67-4fcb-4f99-ba57-bffce41f7970 | Ernest     | Hemingway
(1 row)

veneer=> SELECT pg_backend_pid(), * FROM dunder_mifflin.authors WHERE first_name = 'Ernest';
 pg_backend_pid |                  id                  | first_name | last_name
----------------+--------------------------------------+------------+-----------
            145 | 8e87595c-6941-4082-9090-a2e8af2a9000 | Ernest     | Hemingway
(1 row)

veneer=> SELECT pg_backend_pid(), * FROM initech.authors WHERE first_name = 'Ernest';
 pg_backend_pid |                  id                  | first_name | last_name
----------------+--------------------------------------+------------+-----------
            145 | 48049ea7-f554-4d0f-870c-22419a993ed1 | Ernest     | Hemingway
(1 row)

veneer=> \q
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
2021-09-12 13:53:23.061 UTC 613e0634.91 u:(veneer_app) d:(veneer) LOG:  statement: SELECT pg_backend_pid(), * FROM initech.authors WHERE first_name = 'Ernest';
$
$ make show-logs-shard1
...
2021-09-12 13:53:09.001 UTC 613e0644.67 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-shard2
...
2021-09-12 13:53:17.115 UTC 613e0649.78 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-shard3
...
2021-09-12 13:53:23.078 UTC 613e0653.66 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
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
 54b44bc0-fb42-4937-a5f9-9be5a1bcb844 | 97f2477b-cd10-4474-8899-e19c07270f13 | Anne              | Rice             | The Wolf Gift              | 2012-02-14
 54b44bc0-fb42-4937-a5f9-9be5a1bcb844 | b2d43d29-3a64-4c0d-8741-db8c103db7ee | Anne              | Rice             | Interview with the Vampire | 1976-05-05
 54b44bc0-fb42-4937-a5f9-9be5a1bcb844 | 3537896e-47cc-4bda-a348-a11a56430d8a | Anne              | Rice             | The Queen of the Damned    | 1988-09-12
(3 rows)

veneer=> \q
```

We can then check back in, first on the shards we didn't touch:

```
$ make show-logs-shard2
...
2021-09-12 13:53:17.115 UTC 613e0649.78 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-shard3
...
2021-09-12 13:53:23.078 UTC 613e0653.66 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
```

and then on the two we did:

```
$ make show-logs-veneer
...
2021-09-12 13:53:23.061 UTC 613e0634.91 u:(veneer_app) d:(veneer) LOG:  statement: SELECT pg_backend_pid(), * FROM initech.authors WHERE first_name = 'Ernest';
2021-09-12 13:55:42.987 UTC 613e06d9.b4 u:(veneer_app) d:(veneer) LOG:  statement: SELECT
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
$ make show-logs-shard1
...
2021-09-12 13:53:09.001 UTC 613e0644.67 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
2021-09-12 13:55:43.000 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: SET search_path = pg_catalog
2021-09-12 13:55:43.000 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: SET timezone = 'UTC'
2021-09-12 13:55:43.001 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: SET datestyle = ISO
2021-09-12 13:55:43.001 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: SET intervalstyle = postgres
2021-09-12 13:55:43.002 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: SET extra_float_digits = 3
2021-09-12 13:55:43.002 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-12 13:55:43.004 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  execute <unnamed>: DECLARE c1 CURSOR FOR
        SELECT r1.id, r2.id, r1.first_name, r1.last_name, r2.title, r2.publish_date FROM (bluth_co.authors r1 INNER JOIN bluth_co.books r2 ON (((r1.id = r2.author_id)) AND ((r1.last_name = 'Rice'::text))))
2021-09-12 13:55:43.006 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: FETCH 100 FROM c1
2021-09-12 13:55:43.007 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: CLOSE c1
2021-09-12 13:55:43.007 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
```

## Foreign `JOIN`; Different Shard

To contrast, if we do a `JOIN` for tables on two distinct physical
shards (which should be **ILLEGAL** as an operation in a multitenant system):

```
$ make psql-veneer
psql "postgres://veneer_app:1234abcd@localhost:14797/veneer"
psql (13.4, server 13.3)
Type "help" for help.

veneer=> SELECT
veneer->   c.id AS cyberdyne_id,
veneer->   i.id AS initech_id,
veneer->   c.first_name AS first_name,
veneer->   c.last_name AS last_name
veneer-> FROM
veneer->   cyberdyne.authors AS c
veneer-> INNER JOIN
veneer->   initech.authors AS i
veneer-> ON
veneer->   c.first_name = i.first_name AND
veneer->   c.last_name = i.last_name;
             cyberdyne_id             |              initech_id              | first_name | last_name
--------------------------------------+--------------------------------------+------------+-----------
 9edcf97d-5c7a-46f4-9e44-4575955f2529 | dd1608ad-b6fe-4ba0-b1a4-121c5ce582d3 | Agatha     | Christie
 5b64e1bb-679c-4f1d-9d8e-0ec500be5bf7 | a1497bbb-974d-4ded-ab8f-84a9ff7b2f27 | Anne       | Rice
 1b20af67-4fcb-4f99-ba57-bffce41f7970 | 48049ea7-f554-4d0f-870c-22419a993ed1 | Ernest     | Hemingway
 41b8a3eb-4cea-4e41-beaf-f1e39c969311 | 883441f5-f23e-400b-b5b3-401b587397db | JK         | Rowling
 51184457-91b5-4258-80f8-dca717509b63 | d9c27241-35a5-49ef-bda8-a6d63f64b74e | James      | Joyce
 eed464d9-7998-4884-813e-4c65cd9909ca | fe20a4ba-f286-4b5f-8b20-502efa2b68d4 | John       | Steinbeck
 cec5b4f7-5b2e-403d-9bf9-a7bbf508d56b | 3b423fae-fde8-4116-b019-961995bdd4eb | Kurt       | Vonnegut
(7 rows)

veneer=> \q
```

we see Shard 1 at the same checkpoint we left off:

```
$ make show-logs-shard1
...
2021-09-12 13:55:43.007 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
```

and the three shards involved in the `JOIN` show that only a basic
`SELECT` was done on the two target tables (meaning they had to have been
joined on the Veneer proxy):

```
$ make show-logs-veneer
...
2021-09-12 13:55:42.987 UTC 613e06d9.b4 u:(veneer_app) d:(veneer) LOG:  statement: SELECT
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
2021-09-12 13:58:40.391 UTC 613e078d.cd u:(veneer_app) d:(veneer) LOG:  statement: SELECT
          c.id AS cyberdyne_id,
          i.id AS initech_id,
          c.first_name AS first_name,
          c.last_name AS last_name
        FROM
          cyberdyne.authors AS c
        INNER JOIN
          initech.authors AS i
        ON
          c.first_name = i.first_name AND
          c.last_name = i.last_name;
$
$ make show-logs-shard2
...
2021-09-12 13:53:17.115 UTC 613e0649.78 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
2021-09-12 13:58:40.404 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: SET search_path = pg_catalog
2021-09-12 13:58:40.405 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: SET timezone = 'UTC'
2021-09-12 13:58:40.405 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: SET datestyle = ISO
2021-09-12 13:58:40.406 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: SET intervalstyle = postgres
2021-09-12 13:58:40.406 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: SET extra_float_digits = 3
2021-09-12 13:58:40.407 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-12 13:58:40.420 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  execute <unnamed>: DECLARE c1 CURSOR FOR
        SELECT id, first_name, last_name FROM cyberdyne.authors
2021-09-12 13:58:40.422 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: FETCH 100 FROM c1
2021-09-12 13:58:40.425 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: CLOSE c1
2021-09-12 13:58:40.426 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-shard3
...
2021-09-12 13:53:23.078 UTC 613e0653.66 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
2021-09-12 13:58:40.417 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: SET search_path = pg_catalog
2021-09-12 13:58:40.417 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: SET timezone = 'UTC'
2021-09-12 13:58:40.418 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: SET datestyle = ISO
2021-09-12 13:58:40.418 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: SET intervalstyle = postgres
2021-09-12 13:58:40.419 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: SET extra_float_digits = 3
2021-09-12 13:58:40.419 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-12 13:58:40.423 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  execute <unnamed>: DECLARE c2 CURSOR FOR
        SELECT id, first_name, last_name FROM initech.authors
2021-09-12 13:58:40.424 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: FETCH 100 FROM c2
2021-09-12 13:58:40.425 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: CLOSE c2
2021-09-12 13:58:40.426 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
```

## Foreign `JOIN`; Same Shard

To contrast the previous example, let's do the same foreign `JOIN` but for
`cyberdyne` and `dunder_mifflin`, which both reside on Shard 2.

```
$ make psql-veneer
psql "postgres://veneer_app:1234abcd@localhost:14797/veneer"
psql (13.4, server 13.3)
Type "help" for help.

veneer=> SELECT
veneer->   c.id AS cyberdyne_id,
veneer->   d.id AS dunder_mifflin_id,
veneer->   c.first_name AS first_name,
veneer->   c.last_name AS last_name
veneer-> FROM
veneer->   cyberdyne.authors AS c
veneer-> INNER JOIN
veneer->   dunder_mifflin.authors AS d
veneer-> ON
veneer->   c.first_name = d.first_name AND
veneer->   c.last_name = d.last_name;
             cyberdyne_id             |          dunder_mifflin_id           | first_name | last_name
--------------------------------------+--------------------------------------+------------+-----------
 9edcf97d-5c7a-46f4-9e44-4575955f2529 | 6e5cf0df-cef5-4400-9b49-61801befa706 | Agatha     | Christie
 5b64e1bb-679c-4f1d-9d8e-0ec500be5bf7 | 6976da86-c262-47ba-bf37-576d0fcbe661 | Anne       | Rice
 1b20af67-4fcb-4f99-ba57-bffce41f7970 | 8e87595c-6941-4082-9090-a2e8af2a9000 | Ernest     | Hemingway
 41b8a3eb-4cea-4e41-beaf-f1e39c969311 | 65c46841-2348-498d-aeff-47a797532278 | JK         | Rowling
 51184457-91b5-4258-80f8-dca717509b63 | 813cec6f-04e9-4455-881d-cb282a6bee40 | James      | Joyce
 eed464d9-7998-4884-813e-4c65cd9909ca | ce33cccd-2a14-4df5-b571-c8250f0c81e8 | John       | Steinbeck
 cec5b4f7-5b2e-403d-9bf9-a7bbf508d56b | b8ba9c26-f3bc-4ba9-a6b8-bfb327960f1a | Kurt       | Vonnegut
(7 rows)

veneer=> \q
```

Again a little bookkeeping, the two shards not involved remain at the same
checkpoint:

```
$ make show-logs-shard1
...
2021-09-12 13:55:43.007 UTC 613e06de.7c u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-shard3
...
2021-09-12 13:58:40.426 UTC 613e0790.8f u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
```

The Veneer and Shard 2 logs show that PostgreSQL is able to do the `JOIN` on
the remote (Shard 2) even though the schemas differ. This matches what we
already saw when joing `bluth_co.authors` and `bluth_co.books` from the same
shard.

```
$ make show-logs-veneer
...
2021-09-12 13:58:40.391 UTC 613e078d.cd u:(veneer_app) d:(veneer) LOG:  statement: SELECT
          c.id AS cyberdyne_id,
          i.id AS initech_id,
          c.first_name AS first_name,
          c.last_name AS last_name
        FROM
          cyberdyne.authors AS c
        INNER JOIN
          initech.authors AS i
        ON
          c.first_name = i.first_name AND
          c.last_name = i.last_name;
2021-09-12 14:05:31.851 UTC 613e092a.f1 u:(veneer_app) d:(veneer) LOG:  statement: SELECT
          c.id AS cyberdyne_id,
          d.id AS dunder_mifflin_id,
          c.first_name AS first_name,
          c.last_name AS last_name
        FROM
          cyberdyne.authors AS c
        INNER JOIN
          dunder_mifflin.authors AS d
        ON
        c.first_name = d.first_name AND
        c.last_name = d.last_name;
$
$ make show-logs-shard2
...
2021-09-12 13:58:40.426 UTC 613e0790.a3 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
2021-09-12 14:05:31.864 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: SET search_path = pg_catalog
2021-09-12 14:05:31.864 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: SET timezone = 'UTC'
2021-09-12 14:05:31.864 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: SET datestyle = ISO
2021-09-12 14:05:31.865 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: SET intervalstyle = postgres
2021-09-12 14:05:31.865 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: SET extra_float_digits = 3
2021-09-12 14:05:31.865 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-12 14:05:31.866 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  execute <unnamed>: DECLARE c1 CURSOR FOR
        SELECT id, first_name, last_name FROM cyberdyne.authors
2021-09-12 14:05:31.867 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: FETCH 100 FROM c1
2021-09-12 14:05:31.868 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  execute <unnamed>: DECLARE c2 CURSOR FOR
        SELECT id, first_name, last_name FROM dunder_mifflin.authors
2021-09-12 14:05:31.869 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: FETCH 100 FROM c2
2021-09-12 14:05:31.869 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: CLOSE c2
2021-09-12 14:05:31.869 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: CLOSE c1
2021-09-12 14:05:31.869 UTC 613e092b.c7 u:(bookstore_app) d:(bookstore) LOG:  statement: COMMIT TRANSACTION
```

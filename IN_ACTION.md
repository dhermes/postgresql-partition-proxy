# PostgreSQL Partition Proxy in Action

## Initialize PostgreSQL Instances

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
0c94aa5e83b0   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:29948->5432/tcp   dev-postgres-shard1
ddb93e29b7af   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:13366->5432/tcp   dev-postgres-shard2
0d047aded5a6   postgres:13.3-alpine3.14   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:11033->5432/tcp   dev-postgres-shard3
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
            389 | ed62a6c5-3ebc-41ea-a63c-ba48c400068a | Ernest     | Hemingway
(1 row)

veneer=> SELECT pg_backend_pid(), * FROM cyberdyne.authors WHERE first_name = 'Ernest';
 pg_backend_pid |                  id                  | first_name | last_name
----------------+--------------------------------------+------------+-----------
            389 | dd01165c-c228-48af-8017-5f75ac434394 | Ernest     | Hemingway
(1 row)

veneer=> SELECT pg_backend_pid(), * FROM initech.authors WHERE first_name = 'Ernest';
 pg_backend_pid |                  id                  | first_name | last_name
----------------+--------------------------------------+------------+-----------
            389 | c9927c3d-16ba-4d9a-91ce-45d8dd48d003 | Ernest     | Hemingway
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
 3ccff0b6-cdbd-4e23-8614-e48c3abce325 | b7c833c7-f62a-4e57-bccf-c21d3f75f79b | Agatha     | Christie
 2c33a706-e53b-4d9f-a37e-bb1179b74fca | 770fbcbe-abdc-4aed-a5b9-edcfbf21012b | Anne       | Rice
 dd01165c-c228-48af-8017-5f75ac434394 | c9927c3d-16ba-4d9a-91ce-45d8dd48d003 | Ernest     | Hemingway
 a575526a-831e-47c3-b069-9778238496db | 19610e44-a291-4dea-b76b-e5a0b6177624 | JK         | Rowling
 1209bdc8-d534-4f4f-85b5-beeca44ec200 | 7683f2fd-1288-404b-9dd6-ff47e2cad12d | James      | Joyce
 be29945e-c623-4188-a751-37435e1067ef | b1096d5b-d97b-4a8a-8f4c-2ef4b21b11a7 | John       | Steinbeck
 ef62d3a5-d73b-493b-affb-817ee1658ef2 | 97a1c52d-0695-4d2a-89ee-2589a15252bb | Kurt       | Vonnegut
(7 rows)

veneer=> \q
```

we see Bluth Co at the same checkpoint:

```
$ make show-logs-bluth-co
...
2021-09-11 07:37:33.793 UTC 613c5cbd.e9 u:(bluth_co_app) d:(bluth_co) LOG:  statement: COMMIT TRANSACTION
```

and the three shards involved in the `JOIN` show that only a basic
`SELECT` was done on the two target tables (meaning they had to have been
joined on the Veneer proxy):

```
$ make show-logs-veneer
...
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
2021-09-11 07:45:03.825 UTC 613c5dc8.156 u:(veneer_app) d:(veneer) LOG:  statement: SELECT
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
$ make show-logs-cyberdyne
...
2021-09-11 07:25:05.366 UTC 613c59d1.98 u:(cyberdyne_admin) d:(cyberdyne) LOG:  statement: COMMIT TRANSACTION
2021-09-11 07:45:03.858 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: SET search_path = pg_catalog
2021-09-11 07:45:03.860 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: SET timezone = 'UTC'
2021-09-11 07:45:03.861 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: SET datestyle = ISO
2021-09-11 07:45:03.864 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: SET intervalstyle = postgres
2021-09-11 07:45:03.865 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: SET extra_float_digits = 3
2021-09-11 07:45:03.867 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-11 07:45:03.905 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  execute <unnamed>: DECLARE c1 CURSOR FOR
        SELECT id, first_name, last_name FROM cyberdyne.authors
2021-09-11 07:45:03.908 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: FETCH 100 FROM c1
2021-09-11 07:45:03.917 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: CLOSE c1
2021-09-11 07:45:03.919 UTC 613c5e7f.10b u:(cyberdyne_app) d:(cyberdyne) LOG:  statement: COMMIT TRANSACTION
$
$ make show-logs-initech
...
2021-09-11 07:25:05.486 UTC 613c59d1.96 u:(initech_admin) d:(initech) LOG:  statement: COMMIT TRANSACTION
2021-09-11 07:45:03.892 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: SET search_path = pg_catalog
2021-09-11 07:45:03.895 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: SET timezone = 'UTC'
2021-09-11 07:45:03.897 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: SET datestyle = ISO
2021-09-11 07:45:03.899 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: SET intervalstyle = postgres
2021-09-11 07:45:03.901 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: SET extra_float_digits = 3
2021-09-11 07:45:03.903 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: START TRANSACTION ISOLATION LEVEL REPEATABLE READ
2021-09-11 07:45:03.911 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  execute <unnamed>: DECLARE c2 CURSOR FOR
        SELECT id, first_name, last_name FROM initech.authors
2021-09-11 07:45:03.913 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: FETCH 100 FROM c2
2021-09-11 07:45:03.915 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: CLOSE c2
2021-09-11 07:45:03.920 UTC 613c5e7f.130 u:(initech_app) d:(initech) LOG:  statement: COMMIT TRANSACTION
```

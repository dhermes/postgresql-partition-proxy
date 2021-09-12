BEGIN;
----
DROP SERVER IF EXISTS shard1_server CASCADE;
CREATE SERVER shard1_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'dev-postgres-shard1.', port '5432', dbname 'bookstore');
CREATE USER MAPPING FOR veneer_admin
  SERVER shard1_server
  OPTIONS (user 'bookstore_admin', password 'efgh5678');
CREATE USER MAPPING FOR veneer_app
  SERVER shard1_server
  OPTIONS (user 'bookstore_app', password '5678efgh');
----
do
$$
declare
  l_rec record;
begin
  for l_rec in (select foreign_table_name from information_schema.foreign_tables WHERE foreign_table_schema = 'bluth_co') loop
     execute format('DROP FOREIGN TABLE bluth_co.%I', l_rec.foreign_table_name);
  end loop;
end;
$$;
----
IMPORT FOREIGN SCHEMA bluth_co
  FROM SERVER shard1_server
  INTO bluth_co;
----
COMMIT;

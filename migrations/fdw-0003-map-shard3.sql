BEGIN;
----
DROP SERVER IF EXISTS shard3_server CASCADE;
CREATE SERVER shard3_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'dev-postgres-shard3.', port '5432', dbname 'initech');
CREATE USER MAPPING FOR veneer_admin
  SERVER shard3_server
  OPTIONS (user 'initech_admin', password 'mnop3456');
CREATE USER MAPPING FOR veneer_app
  SERVER shard3_server
  OPTIONS (user 'initech_app', password '3456mnop');
----
do
$$
declare
  l_rec record;
begin
  for l_rec in (select foreign_table_name from information_schema.foreign_tables WHERE foreign_table_schema = 'initech') loop
     execute format('DROP FOREIGN TABLE initech.%I', l_rec.foreign_table_name);
  end loop;
end;
$$;
----
IMPORT FOREIGN SCHEMA initech
  FROM SERVER shard3_server
  INTO initech;
----
COMMIT;

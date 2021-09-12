BEGIN;
----
DROP SERVER IF EXISTS shard2_server CASCADE;
CREATE SERVER shard2_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'dev-postgres-shard2.', port '5432', dbname 'bookstore');
CREATE USER MAPPING FOR veneer_admin
  SERVER shard2_server
  OPTIONS (user 'bookstore_admin', password 'ijkl9012');
CREATE USER MAPPING FOR veneer_app
  SERVER shard2_server
  OPTIONS (user 'bookstore_app', password '9012ijkl');
----
do
$$
declare
  l_rec record;
begin
  for l_rec in (select foreign_table_name from information_schema.foreign_tables WHERE foreign_table_schema = 'cyberdyne') loop
     execute format('DROP FOREIGN TABLE cyberdyne.%I', l_rec.foreign_table_name);
  end loop;
end;
$$;
----
IMPORT FOREIGN SCHEMA cyberdyne
  FROM SERVER shard2_server
  INTO cyberdyne;
----
COMMIT;

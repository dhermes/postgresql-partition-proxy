BEGIN;
----
DROP SERVER IF EXISTS bluth_co_server CASCADE;
CREATE SERVER bluth_co_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'host.docker.internal', port '29948', dbname 'bluth_co');
CREATE USER MAPPING FOR veneer_admin
  SERVER bluth_co_server
  OPTIONS (user 'bluth_co_admin', password 'efgh5678');
CREATE USER MAPPING FOR veneer_app
  SERVER bluth_co_server
  OPTIONS (user 'bluth_co_app', password '5678efgh');
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
  FROM SERVER bluth_co_server
  INTO bluth_co;
----
COMMIT;

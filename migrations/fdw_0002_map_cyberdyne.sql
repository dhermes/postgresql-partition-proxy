BEGIN;
----
DROP SERVER IF EXISTS cyberdyne_server CASCADE;
CREATE SERVER cyberdyne_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'host.docker.internal', port '13366', dbname 'cyberdyne');
CREATE USER MAPPING FOR veneer_admin
  SERVER cyberdyne_server
  OPTIONS (user 'cyberdyne_admin', password 'ijkl9012');
CREATE USER MAPPING FOR veneer_app
  SERVER cyberdyne_server
  OPTIONS (user 'cyberdyne_app', password '9012ijkl');
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
  FROM SERVER cyberdyne_server
  INTO cyberdyne;
----
COMMIT;

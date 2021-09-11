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
DROP SCHEMA IF EXISTS bluth_co;
CREATE SCHEMA bluth_co;
IMPORT FOREIGN SCHEMA bluth_co
  FROM SERVER bluth_co_server
  INTO bluth_co;
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
DROP SCHEMA IF EXISTS cyberdyne;
CREATE SCHEMA cyberdyne;
IMPORT FOREIGN SCHEMA cyberdyne
  FROM SERVER cyberdyne_server
  INTO cyberdyne;
----
DROP SERVER IF EXISTS initech_server CASCADE;
CREATE SERVER initech_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'host.docker.internal', port '11033', dbname 'initech');
CREATE USER MAPPING FOR veneer_admin
  SERVER initech_server
  OPTIONS (user 'initech_admin', password 'mnop3456');
CREATE USER MAPPING FOR veneer_app
  SERVER initech_server
  OPTIONS (user 'initech_app', password '3456mnop');
DROP SCHEMA IF EXISTS initech;
CREATE SCHEMA initech;
IMPORT FOREIGN SCHEMA initech
  FROM SERVER initech_server
  INTO initech;
----
COMMIT;

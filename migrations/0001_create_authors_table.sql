BEGIN;
----
CREATE TABLE IF NOT EXISTS authors (
  id UUID NOT NULL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL
);
----
ALTER TABLE
  authors
DROP CONSTRAINT IF EXISTS
  uq_authors_full_name;
ALTER TABLE
  authors
ADD CONSTRAINT
  uq_authors_full_name
UNIQUE
  (first_name, last_name);
----
COMMIT;

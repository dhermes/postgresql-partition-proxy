BEGIN;
----
CREATE TABLE IF NOT EXISTS books (
  id UUID NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  author_id UUID REFERENCES authors (id),
  publish_date DATE
);
----
ALTER TABLE
  books
DROP CONSTRAINT IF EXISTS
  uq_books_author_title;
ALTER TABLE
  books
ADD CONSTRAINT
  uq_books_author_title
UNIQUE
  (author_id, title);
----
COMMIT;

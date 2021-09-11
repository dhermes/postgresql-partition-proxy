CREATE TABLE IF NOT EXISTS books (
  id UUID NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  author_id UUID REFERENCES authors (id),
  publish_date DATE
);

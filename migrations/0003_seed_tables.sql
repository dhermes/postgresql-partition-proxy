INSERT INTO
  authors (id, first_name, last_name)
VALUES
  (gen_random_uuid(), 'Anne', 'Rice'),
  (gen_random_uuid(), 'John', 'Steinbeck'),
  (gen_random_uuid(), 'JK', 'Rowling'),
  (gen_random_uuid(), 'Ernest', 'Hemingway'),
  (gen_random_uuid(), 'Kurt', 'Vonnegut'),
  (gen_random_uuid(), 'Agatha', 'Christie'),
  (gen_random_uuid(), 'James', 'Joyce');
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'The Wolf Gift' AS title,
  id AS author_id,
  DATE '2012-02-14' AS publish_date
FROM
  authors
WHERE
  first_name = 'Anne' AND
  last_name = 'Rice';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'Interview with the Vampire' AS title,
  id AS author_id,
  DATE '1976-05-05' AS publish_date
FROM
  authors
WHERE
  first_name = 'Anne' AND
  last_name = 'Rice';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'The Queen of the Damned' AS title,
  id AS author_id,
  DATE '1988-09-12' AS publish_date
FROM
  authors
WHERE
  first_name = 'Anne' AND
  last_name = 'Rice';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'East of Eden' AS title,
  id AS author_id,
  DATE '1952-09-19' AS publish_date
FROM
  authors
WHERE
  first_name = 'John' AND
  last_name = 'Steinbeck';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'Harry Potter and the Goblet of Fire' AS title,
  id AS author_id,
  DATE '2000-07-08' AS publish_date
FROM
  authors
WHERE
  first_name = 'JK' AND
  last_name = 'Rowling';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'Murder on the Orient Express' AS title,
  id AS author_id,
  DATE '1934-01-01' AS publish_date
FROM
  authors
WHERE
  first_name = 'Agatha' AND
  last_name = 'Christie';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'Ulysses' AS title,
  id AS author_id,
  DATE '1922-02-02' AS publish_date
FROM
  authors
WHERE
  first_name = 'James' AND
  last_name = 'Joyce';
----
INSERT INTO
  books (id, title, author_id, publish_date)
SELECT
  gen_random_uuid() AS id,
  'Finnegans Wake' AS title,
  id AS author_id,
  DATE '1939-05-04' AS publish_date
FROM
  authors
WHERE
  first_name = 'James' AND
  last_name = 'Joyce';

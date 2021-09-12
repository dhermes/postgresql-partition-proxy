#!/bin/bash

set -e

if ! [ -x "$(command -v docker)" ]; then
  echo "Error: docker is not installed." >&2
  exit 1
fi

if [ -z "${DB_CONTAINER_NAME}" ]; then
  echo "DB_CONTAINER_NAME environment variable should be set by the caller." >&2
  exit 1
fi

# NOTE: We assume the lexicographic log files are sorted correctly.
LOG_FILES=$(docker exec "${DB_CONTAINER_NAME}" ls -1 /var/lib/postgresql/data/pg_log | sort)
for LOG_FILE in ${LOG_FILES}
do
  docker exec "${DB_CONTAINER_NAME}" cat "/var/lib/postgresql/data/pg_log/${LOG_FILE}"
done

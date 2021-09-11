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

LOG_FILES=$(docker exec "${DB_CONTAINER_NAME}" ls -1 /var/lib/postgresql/data/pg_log)
LOG_FILE_COUNT=$(echo "${LOG_FILES}" | wc -l | tr -d '[:space:]')
if [[ "${LOG_FILE_COUNT}" != "1" ]]; then
  echo "Error: Found ${LOG_FILE_COUNT} log files, expected 1." >&2
  exit 1
fi

LOG_FILE="/var/lib/postgresql/data/pg_log/${LOG_FILES}"
docker exec "${DB_CONTAINER_NAME}" cat "${LOG_FILE}"

#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <dump-file>" >&2
  exit 1
fi

DUMP_FILE=$(realpath "$1")
test -s "$DUMP_FILE"
STACK_DIR="${STACK_DIR:-/opt/sonarqube}"

cd "$STACK_DIR"
docker compose exec -T db pg_restore --list <"$DUMP_FILE" >/dev/null
docker compose stop sonarqube
docker compose exec -T db sh -c 'exec pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --exit-on-error --single-transaction' <"$DUMP_FILE"
# Indexes must be rebuilt from the restored database, with SonarQube stopped.
docker compose run --rm --no-deps --entrypoint sh sonarqube -c 'rm -rf /opt/sonarqube/data/es*'
docker compose start sonarqube
echo "Database restored; verify SonarQube health after index rebuilding completes"

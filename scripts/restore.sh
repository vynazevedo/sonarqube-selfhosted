#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <dump-file>" >&2
  exit 1
fi

DUMP_FILE=$1
STACK_DIR="${STACK_DIR:-/opt/sonarqube}"

cd "$STACK_DIR"
set -a
# shellcheck disable=SC1091
source ./.env
set +a

docker compose stop sonarqube
docker compose exec -T db pg_restore -U "$SONAR_DB_USER" -d "$SONAR_DB_NAME" --clean --if-exists --no-owner <"$DUMP_FILE"
docker compose start sonarqube
echo "Restore complete"

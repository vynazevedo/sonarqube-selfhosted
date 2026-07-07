#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/sonarqube}"
BACKUP_DIR="${BACKUP_DIR:-$STACK_DIR/backups}"
LOCAL_RETENTION_DAYS="${LOCAL_RETENTION_DAYS:-3}"

cd "$STACK_DIR"
set -a
# shellcheck disable=SC1091
source ./.env
set +a

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DUMP="$BACKUP_DIR/sonar-$TIMESTAMP.dump"
docker compose exec -T db pg_dump -U "$SONAR_DB_USER" -Fc "$SONAR_DB_NAME" >"$DUMP"
echo "Wrote $DUMP"

if [ -n "${BACKUP_S3_BUCKET:-}" ]; then
  aws s3 cp "$DUMP" "s3://$BACKUP_S3_BUCKET/pg_dump/" --only-show-errors
fi

find "$BACKUP_DIR" -name '*.dump' -mtime +"$LOCAL_RETENTION_DAYS" -delete

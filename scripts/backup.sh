#!/usr/bin/env bash
set -euo pipefail
umask 077

STACK_DIR="${STACK_DIR:-/opt/sonarqube}"
BACKUP_DIR="${BACKUP_DIR:-$STACK_DIR/backups}"
LOCAL_RETENTION_DAYS="${LOCAL_RETENTION_DAYS:-3}"

cd "$STACK_DIR"
mkdir -p "$BACKUP_DIR"
exec 9>"$BACKUP_DIR/.backup.lock"
flock -n 9 || { echo "Another backup is running" >&2; exit 1; }

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DUMP="$BACKUP_DIR/sonar-$TIMESTAMP.dump"
trap 'rm -f "$DUMP.partial"' EXIT
docker compose exec -T db sh -c 'exec pg_dump -U "$POSTGRES_USER" -Fc "$POSTGRES_DB"' >"$DUMP.partial"
test -s "$DUMP.partial"
mv "$DUMP.partial" "$DUMP"
echo "Wrote $DUMP"

if [ -n "${BACKUP_S3_BUCKET:-}" ]; then
  aws s3 cp "$DUMP" "s3://$BACKUP_S3_BUCKET/pg_dump/" --only-show-errors
fi

touch "$BACKUP_DIR/.last-success"
find "$BACKUP_DIR" -name '*.dump' -mtime +"$LOCAL_RETENTION_DAYS" -delete

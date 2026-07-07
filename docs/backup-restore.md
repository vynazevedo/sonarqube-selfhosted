# Backup and restore

Two independent layers protect your data. The SonarQube state that matters is the PostgreSQL database plus the `sonarqube_data` and `sonarqube_extensions` volumes.

| Layer | What | When | Where | Retention |
| --- | --- | --- | --- | --- |
| Logical | `pg_dump` custom format | Daily 02:00 UTC | Local + S3 `pg_dump/` prefix | 3 days local, `backup_retention_days` in S3 |
| Physical | EBS snapshot of the data volume | Daily 03:00 UTC | EBS snapshots | `snapshot_retention_days` |

The dump runs before the snapshot, so every snapshot contains the latest dump.

## Manual backup

On the instance (`aws ssm start-session --target <instance-id>`):

```bash
sudo systemctl start sonarqube-backup.service
```

## Restore from pg_dump

Use this for database corruption or migrating to a new server. On the instance:

```bash
cd /opt/sonarqube
aws s3 cp s3://<backup-bucket>/pg_dump/sonar-YYYYMMDD-HHMMSS.dump .
sudo docker compose stop sonarqube
set -a; sudo cat .env > /tmp/env && source /tmp/env; set +a; rm /tmp/env
sudo docker compose exec -T db pg_restore -U "$SONAR_DB_USER" -d "$SONAR_DB_NAME" --clean --if-exists --no-owner < sonar-YYYYMMDD-HHMMSS.dump
sudo docker compose start sonarqube
```

Compose-only deployments: run `scripts/restore.sh <dump-file>` instead.

Note that a pg_dump restore recovers the database but not the Elasticsearch indexes; SonarQube rebuilds them on startup, which can take a while on large instances.

## Restore from EBS snapshot

Use this for full disaster recovery, including a destroyed instance or volume.

```bash
terraform apply -var data_volume_snapshot_id=snap-0abc123...
```

Terraform creates the data volume from the snapshot and the instance boots against it, finding the existing filesystem intact. If the existing volume still exists in state and must be abandoned, remove it first with `terraform state rm module.sonarqube.aws_ebs_volume.data` or taint it.

## What to test

Run a restore drill after first deployment: take a manual backup, destroy the stack in a sandbox, restore from the snapshot and verify projects and users are present. A backup you never restored is not a backup.

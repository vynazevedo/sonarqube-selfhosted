# Backup and restore

Two independent layers protect your data. The SonarQube state that matters is the PostgreSQL database plus the `sonarqube_data` and `sonarqube_extensions` volumes.

| Layer | What | When | Where | Retention |
| --- | --- | --- | --- | --- |
| Logical | `pg_dump` custom format | Daily 02:00 UTC | Local + S3 `pg_dump/` prefix | 3 days local, `backup_retention_days` in S3 |
| Physical | EBS snapshot of the data volume | Daily 03:00 UTC | EBS snapshots | `snapshot_retention_days` |

AWS deployments store completed dumps in `/var/lib/docker/sonarqube-backups`, on the snapshotted data volume. A snapshot includes only dumps completed before it was taken; timers do not guarantee completion order. Live EBS snapshots are crash-consistent, not a coordinated PostgreSQL logical backup. S3 uploads provide an independent copy.

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
sudo /opt/sonarqube/bin/restore.sh sonar-YYYYMMDD-HHMMSS.dump
```

Compose-only deployments: run `scripts/restore.sh <dump-file>` instead.

The restore script checks the dump before stopping SonarQube, restores in a transaction and stops on errors. It clears stale Elasticsearch indexes with SonarQube stopped so they are rebuilt from the restored database. If restoration fails, the application remains stopped for investigation. Rebuilding indexes can take a while.

## Restore from EBS snapshot

Use this for full disaster recovery, including a destroyed instance or volume.

```bash
terraform apply -var data_volume_snapshot_id=snap-0abc123...
```

Terraform creates the data volume from the snapshot and the instance boots against it, finding the existing filesystem intact. Review the replacement plan carefully and retain a recovery snapshot before replacing an existing data volume. Keep the original database password in SSM and Terraform state: restoring a volume into a fresh stack with a newly generated password does not change the password stored inside PostgreSQL. For a fresh stack, prefer a logical restore into its newly initialized database.

## What to test

Run a restore drill after first deployment: take a manual backup, destroy the stack in a sandbox, restore from the snapshot and verify projects and users are present. A backup you never restored is not a backup.

## Backup failure detection

The backup writes a temporary `.partial` file, renames it after `pg_dump` succeeds and updates `.last-success` only after the configured S3 upload succeeds. Concurrent backup runs are rejected. With CloudWatch alarms enabled, a backup older than 26 hours triggers the freshness alarm. Dumps are restricted to the owner and expired locally after three days. The first deployment needs a manual backup to establish its initial success marker.

To download the latest logical backup, use the S3 object directly; do not assume a snapshot contains a dump from the same day. Before a full disaster-recovery drill, preserve the Terraform state and SSM password as well as the snapshots. Never destroy the production stack to test recovery.

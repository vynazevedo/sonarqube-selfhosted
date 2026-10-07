# Upgrading

## SonarQube

Pin an exact patch release and upgrade deliberately:

```hcl
sonarqube_image = "sonarqube:26.9.0.129388-community"
```

Applying replaces the instance (the image tag is part of the rendered user data). The data volume, Elastic IP, database password and backups all survive; expect a few minutes of downtime. SonarQube migrates the database schema on first start after an upgrade; for major version jumps read the SonarSource upgrade notes and always take a manual backup first:

```bash
aws ssm start-session --target <instance-id>
sudo systemctl start sonarqube-backup.service
```

Compose-only deployments: change `SONAR_IMAGE` in `.env`, then `docker compose pull && docker compose up -d`.

Community Build uses its own release numbering. Follow the upgrade path for the source and target Community Build versions; do not apply commercial Server LTA naming to Community images.

## PostgreSQL

Minor updates (16.4 to 16.x) are safe image bumps. Major version upgrades (16 to 17) are not automatic: postgres containers cannot start a 16 data directory on 17. Procedure:

1. Take a manual backup (dump lands in S3).
2. Update the postgres image tag in `docker/docker-compose.yml`.
3. On the instance: stop the stack, move `/var/lib/docker/volumes/sonarqube_postgres_data` aside, start the db service, restore the dump with `pg_restore`, start the rest.

The full restore procedure is in [backup and restore](backup-restore.md).

## The module itself

Pin a release tag and read the changelog before bumping:

```hcl
source = "github.com/vynazevedo/sonarqube-selfhosted//terraform?ref=v1.0.0"
```

Breaking changes only happen in major versions. Always run `terraform plan` and check whether the instance will be replaced; replacement retains the separately managed data volume but causes downtime. Back up first and inspect any planned volume replacement.

## Instance replacement, summarized

These changes replace the EC2 instance: explicit instance replacement to adopt a new AMI (AMI drift is ignored by default), anything in user data (image tags, domain, extra_env). What survives: data volume (all projects, users, settings, certificates), Elastic IP, SSM parameter, S3 backups, EBS snapshots.

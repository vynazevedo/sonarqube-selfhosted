# Compose-only deployment

Run SonarQube on any Linux host with Docker, no AWS required. If you want a fully automated AWS deployment, use the [Terraform module](../terraform/) instead.

## Prerequisites

- Linux host with 8 GB RAM and 50 GB of disk (see [sizing](../docs/sizing.md))
- Docker Engine 24+ with the Compose plugin
- A DNS record for your domain pointing to the host
- Ports 80 and 443 reachable from the internet (port 80 is required for the ACME HTTP-01 challenge)

The embedded Elasticsearch requires kernel settings that containers cannot set themselves:

```bash
cat <<'EOF' | sudo tee /etc/sysctl.d/99-sonarqube.conf
vm.max_map_count=524288
fs.file-max=131072
EOF
sudo sysctl --system
```

## Quickstart

```bash
cp .env.example .env && chmod 600 .env
"$EDITOR" .env
docker compose up -d
docker compose ps
```

Open `https://<your-domain>`, log in with `admin` / `admin` and change the password immediately.

## Backups

Reference scripts live in [scripts/](../scripts/). Schedule `backup.sh` with cron or a systemd timer on the host. See [backup and restore](../docs/backup-restore.md) for the full runbook.

## Operations

- Logs: `docker compose logs -f sonarqube`
- Upgrade: change `SONAR_IMAGE` in `.env`, then `docker compose pull && docker compose up -d` (see [upgrading](../docs/upgrading.md))
- Troubleshooting: see [troubleshooting](../docs/troubleshooting.md)

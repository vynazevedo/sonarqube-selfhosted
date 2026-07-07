# Troubleshooting

## Getting a shell

```bash
aws ssm start-session --target <instance-id>
sudo -i
```

## Where to look first

| Symptom | Check |
| --- | --- |
| Instance came up but nothing works | `cat /var/log/cloud-init-output.log` |
| Stack not running | `systemctl status sonarqube.service` and `docker compose -f /opt/sonarqube/docker-compose.yml ps` |
| SonarQube unhealthy | `docker compose -f /opt/sonarqube/docker-compose.yml logs sonarqube` |
| No certificate / TLS errors | `docker compose -f /opt/sonarqube/docker-compose.yml logs caddy` |
| Backup failures | `journalctl -u sonarqube-backup.service` |

## Common failures

### SonarQube exits at startup with a bootstrap check error

The Elasticsearch bootstrap checks fail when kernel limits are missing. Verify:

```bash
sysctl vm.max_map_count
```

Expected 524288. The user data sets this; if you see the default 65530 the sysctl file did not apply. Re-run `sysctl --system` and restart the service.

### Caddy cannot obtain a certificate

- DNS for your domain must resolve to the Elastic IP before the ACME challenge can pass. Check with `dig +short sonar.example.com`.
- Port 80 must be reachable from the internet; the HTTP-01 challenge uses it. Do not remove it from `allowed_cidrs` thinking it is only a redirect.
- Let's Encrypt rate limits: repeated failed attempts throttle issuance for the domain. Fix DNS first, then restart Caddy: `docker compose -f /opt/sonarqube/docker-compose.yml restart caddy`.
- Cloudflare users: keep the record in DNS-only mode (grey cloud). With the proxy enabled (orange cloud) the HTTP-01 challenge is unreliable and visitors get Cloudflare's edge certificate instead of yours. Proxied mode requires switching Caddy to the DNS-01 challenge with a custom Caddy build that includes the Cloudflare module, or terminating with a Cloudflare Origin CA certificate.

### First boot is slow

`dnf update`, image pulls and SonarQube's first Elasticsearch index build take 5 to 10 minutes on a t4g.large. Watch progress in `/var/log/cloud-init-output.log` and then in the sonarqube container logs.

### Webhooks or GitHub OAuth callback point to the wrong URL

`SONAR_CORE_SERVERBASEURL` must match your public URL. It is derived from the `domain` variable; if you changed the domain, apply again (instance replacement, data survives).

### Data volume did not mount

The user data waits up to 5 minutes for the EBS attachment. Check `lsblk` and `/etc/fstab`, then `mount -a`. If the volume is attached but empty when it should not be, stop and verify you did not create a fresh volume; see [backup and restore](backup-restore.md) before doing anything destructive.

### Analysis fails from CI with 401

The token is missing, revoked or belongs to another project. Generate a project analysis token and update the repository secret.

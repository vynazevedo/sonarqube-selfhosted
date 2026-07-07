# Sizing

## Baseline

The default `t4g.large` (2 vCPU, 8 GB RAM, Graviton) with a 50 GB data volume comfortably serves a small to mid-sized org: tens of projects, a few million lines of code, a handful of concurrent analyses. SonarQube's default JVM heaps fit in 8 GB alongside PostgreSQL and Caddy.

## When to scale up

Watch for these signals:

- Background tasks queueing for long periods (Administration > Background Tasks)
- Elasticsearch heap pressure in `docker compose logs sonarqube`
- Sustained CPU above 80 percent during work hours (enable `enable_cloudwatch_alarms`)

Move to `t4g.xlarge` (16 GB) by changing `instance_type`, then raise the heaps through `extra_env`:

```hcl
instance_type = "t4g.xlarge"
extra_env = {
  SONAR_WEB_JAVAOPTS              = "-Xmx1g -Xms256m"
  SONAR_CE_JAVAOPTS               = "-Xmx2g -Xms512m"
  SONAR_SEARCH_JAVAADDITIONALOPTS = "-Xmx2g -Xms2g"
}
```

Compose-only deployments set the same variables in `.env`.

Changing `instance_type` replaces the instance; data survives on the data volume (see [architecture](architecture.md)).

## Disk growth

Elasticsearch indexes and analysis reports grow with project count and history. The data volume can be grown live: raise `data_volume_size`, apply, then on the instance run `sudo xfs_growfs /var/lib/docker`. Keep usage under 80 percent; the optional disk alarm fires at that threshold.

## Cost expectations (us-east-1, on-demand, approximate)

| Item | Monthly |
| --- | --- |
| t4g.large | ~USD 49 |
| 30 GB root + 50 GB data gp3 | ~USD 7 |
| Elastic IP (attached), SSM, DLM | ~USD 0 |
| S3 backups, snapshots | usually < USD 5 |

A 1-year no-upfront compute savings plan cuts the instance cost by roughly 30 percent.

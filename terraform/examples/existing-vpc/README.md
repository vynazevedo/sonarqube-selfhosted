# Existing VPC example

Deploys the SonarQube module into a VPC and public subnet you already own. The subnet must route 0.0.0.0/0 to an internet gateway; the instance needs egress to pull packages and container images, and ingress on 80/443 for ACME and users.

## Usage

```bash
terraform init
terraform apply \
  -var vpc_id=vpc-0abc123 \
  -var subnet_id=subnet-0def456 \
  -var domain=sonar.example.com \
  -var acme_email=admin@example.com
```

Create an A record for your domain pointing at the `public_ip` output, or pass `route53_zone_id` to have it created automatically.

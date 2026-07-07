# Complete example

Creates a minimal VPC (one public subnet with an internet gateway) and deploys the SonarQube module into it. This is the fastest path from zero to a running server.

## Usage

```bash
terraform init
terraform apply \
  -var domain=sonar.example.com \
  -var acme_email=admin@example.com
```

If your DNS zone is in Route53, pass `-var route53_zone_id=Z123...` and the A record is created for you. Otherwise create an A record for your domain pointing at the `public_ip` output. Caddy issues the TLS certificate automatically once DNS resolves.

First boot takes 5 to 10 minutes (system update, image pulls, SonarQube startup). Then open the `sonarqube_url` output, log in with `admin` / `admin` and change the password immediately.

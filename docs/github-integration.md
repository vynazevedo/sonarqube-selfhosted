# GitHub integration

## What Community Build can and cannot do

| Capability | Community Build | Developer Edition+ |
| --- | --- | --- |
| Analyze the main branch | Yes | Yes |
| Quality gate via API / CI | Yes | Yes |
| Import projects from GitHub | Yes | Yes |
| Sign in with GitHub | Yes | Yes |
| Pull request decoration | No | Yes |
| Multi-branch analysis | No | Yes |

If you need PR feedback inside GitHub with Community Build, a common pattern is: SonarQube as the quality gate on main (this repo's [scanner workflow](../examples/github-actions/)), plus a lightweight scanner such as Semgrep running directly on pull requests.

## Sign in with GitHub (recommended for orgs)

1. In your GitHub org, create a GitHub App: Settings > Developer settings > GitHub Apps.
   - Homepage URL: `https://sonar.example.com`
   - Callback URL: `https://sonar.example.com/oauth2/callback/github`
   - Permissions: read-only access to Organization members and Email addresses
2. In SonarQube: Administration > Configuration > Authentication > GitHub, fill in the App ID, client ID, client secret, private key and your organization name.
3. Enable "Allow users to sign up" restricted to your organization.

The module already sets `SONAR_CORE_SERVERBASEURL`, which is required for the OAuth callback to work.

## Analyzing repositories

1. Create the project in SonarQube (manually or through the GitHub import).
2. Generate a project analysis token.
3. Add the [scanner workflow](../examples/github-actions/sonarqube-scan.yml) to the repository with `SONAR_HOST_URL` as a variable and `SONAR_TOKEN` as a secret. Prefer org-level configuration when rolling out to many repositories.

## Webhooks

To notify external systems when analysis completes, configure webhooks in SonarQube under Administration > Configuration > Webhooks. Outbound HTTPS from the instance is allowed by default.

## Token hygiene

- One analysis token per project, stored only in GitHub secrets.
- Rotate tokens when people leave the team.
- Never use the admin account for analysis.

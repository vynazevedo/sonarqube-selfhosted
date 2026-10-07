# GitHub Actions scanner example

Copy `sonarqube-scan.yml` into `.github/workflows/` of each repository you want analyzed.

## Setup

1. In SonarQube, create the project and generate a project analysis token: Project > Settings > Analysis tokens.
2. Configure the following in GitHub:
   - Organization variable `SONAR_HOST_URL`: your server URL, for example `https://sonar.example.com`
   - Repository variable `SONAR_PROJECT_KEY`: the project key
   - Repository secret `SONAR_TOKEN`: the project analysis token
3. Add a `sonar-project.properties` file to the repository root for source paths, exclusions and coverage settings:

```properties
sonar.sources=.
```

Use one token per project. Never reuse the admin credential or a user token across repositories.

## Community Build limitations

The workflow analyzes the repository default branch only. SonarQube Community Build does not support pull request decoration or multi-branch analysis; those require Developer Edition or above. A common pattern is to keep this workflow as the quality gate on main and run a lightweight scanner such as Semgrep on pull requests. See [GitHub integration](../../docs/github-integration.md) for details.

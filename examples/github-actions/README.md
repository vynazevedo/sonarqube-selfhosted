# GitHub Actions scanner example

Copy `sonarqube-scan.yml` into `.github/workflows/` of each repository you want analyzed.

## Setup

1. In SonarQube, create the project and generate a project analysis token: Project > Settings > Analysis tokens.
2. In the GitHub repository (or at the org level), add:
   - Variable `SONAR_HOST_URL`: your server URL, for example `https://sonar.example.com`
   - Secret `SONAR_TOKEN`: the analysis token
3. Add a `sonar-project.properties` file to the repository root:

```properties
sonar.projectKey=my-project
```

Use one token per project. Never reuse the admin credential or a user token across repositories.

## Community Build limitations

The workflow analyzes the main branch only. SonarQube Community Build does not support pull request decoration or multi-branch analysis; those require Developer Edition or above. A common pattern is to keep this workflow as the quality gate on main and run a lightweight scanner such as Semgrep on pull requests. See [GitHub integration](../../docs/github-integration.md) for details.

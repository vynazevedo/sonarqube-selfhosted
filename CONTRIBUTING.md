# Contributing

Thanks for your interest in improving this project. Issues and pull requests are welcome.

## Development setup

You need Terraform >= 1.5, Docker with the Compose plugin, [tflint](https://github.com/terraform-linters/tflint), [trivy](https://github.com/aquasecurity/trivy) and shellcheck.

Run the same checks CI runs before opening a PR:

```bash
terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false && terraform -chdir=terraform validate
terraform -chdir=terraform/examples/complete init -backend=false && terraform -chdir=terraform/examples/complete validate
terraform -chdir=terraform/examples/existing-vpc init -backend=false && terraform -chdir=terraform/examples/existing-vpc validate
tflint --init && tflint --chdir=terraform --config "$(pwd)/.tflint.hcl"
trivy config --severity HIGH,CRITICAL --ignorefile .trivyignore .
shellcheck scripts/*.sh
```

## Pull requests

- Keep changes focused, one logical change per PR.
- Update documentation when behavior changes.
- Add an entry to CHANGELOG.md under Unreleased.
- The canonical compose file in `docker/` is embedded into the EC2 user data by the Terraform module. If you change it, check the rendered user data stays under the 16 KB EC2 limit and validate with `terraform console`.

## Releases

Maintainers release by moving the Unreleased section of CHANGELOG.md to a new version heading, tagging `vX.Y.Z` and pushing the tag. The release workflow publishes the GitHub Release. Versioning follows SemVer; users pin the module with `?ref=vX.Y.Z`.

## Style

- Documentation in English, plain text, no emojis.
- Terraform formatted with `terraform fmt`, variables and outputs always described.
- Shell scripts pass shellcheck.

"""Render real cloud-init with Terraform and check shell syntax and EC2 size."""
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
for monitoring in (False, True):
    values = {
        "compose_file": (ROOT / "docker/docker-compose.yml").read_text(),
        "caddyfile": (ROOT / "docker/Caddyfile").read_text(),
        "backup_script": (ROOT / "scripts/backup.sh").read_text(),
        "restore_script": (ROOT / "scripts/restore.sh").read_text(),
        "region": "us-east-1", "ssm_parameter": "/sonarqube/db-password",
        "domain": "sonar.example.com", "acme_email": "admin@example.com",
        "sonarqube_image": "sonarqube:26.9.0.129388-community",
        "db_user": "sonar", "db_name": "sonar", "compose_version": "v2.32.4",
        "volume_id_nodash": "vol0123456789abcdef0", "backup_bucket": "test-backups" if monitoring else "",
        "enable_cw_agent": monitoring, "deployment_name": "sonarqube",
        "extra_env": {"SONAR_WEB_JAVAOPTS": "-Xmx1g -Xms256m"},
    }
    # jsondecode prevents Terraform from interpreting shell ${...} as HCL templates.
    encoded = json.dumps(json.dumps(values)).replace("${", "$${").replace("%{", "%%{")
    expression = 'jsonencode(templatefile("templates/user-data.sh.tftpl", jsondecode(' + encoded + ')))'
    result = subprocess.run(["terraform", "console", "-no-color"], cwd=ROOT / "terraform",
                            input=expression, text=True, capture_output=True, check=True)
    rendered = json.loads(json.loads(result.stdout))
    assert len(rendered.encode()) < 16384, "EC2 user data exceeds 16 KiB"
    subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)
    # bash -n on the outer script cannot validate scripts inside heredocs.
    for _, script in re.findall(r"<<'(\w+)'\n(#!/(?:usr/bin/env bash|bin/bash)\n.*?)\n\1\n", rendered, re.S):
        subprocess.run(["bash", "-n"], input=script, text=True, check=True)
    print(f"monitoring={monitoring}: {len(rendered.encode())} bytes, shell syntax OK")

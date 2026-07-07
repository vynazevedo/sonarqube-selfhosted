output "sonarqube_url" {
  description = "Public URL of the SonarQube server"
  value       = module.sonarqube.sonarqube_url
}

output "public_ip" {
  description = "Elastic IP to point your DNS record at"
  value       = module.sonarqube.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.sonarqube.instance_id
}

output "ssm_session_command" {
  description = "Command to open a shell on the instance without SSH"
  value       = module.sonarqube.ssm_session_command
}

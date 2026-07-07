output "sonarqube_url" {
  description = "Public URL of the SonarQube server"
  value       = "https://${var.domain}"
}

output "public_ip" {
  description = "Elastic IP of the instance. Point your DNS record here if not using route53_zone_id"
  value       = aws_eip.this.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "ARN of the instance IAM role"
  value       = aws_iam_role.instance.arn
}

output "db_password_ssm_parameter_name" {
  description = "SSM parameter holding the generated PostgreSQL password"
  value       = aws_ssm_parameter.db_password.name
}

output "backup_bucket_name" {
  description = "Name of the S3 backup bucket, null when disabled"
  value       = var.create_backup_bucket ? aws_s3_bucket.backups[0].bucket : null
}

output "data_volume_id" {
  description = "ID of the persistent data EBS volume"
  value       = aws_ebs_volume.data.id
}

output "route53_fqdn" {
  description = "FQDN of the created Route53 record, null when disabled"
  value       = var.route53_zone_id != null ? aws_route53_record.this[0].fqdn : null
}

output "ssm_session_command" {
  description = "Command to open a shell on the instance without SSH"
  value       = "aws ssm start-session --target ${aws_instance.this.id}"
}

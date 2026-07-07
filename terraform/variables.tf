variable "name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "sonarqube"
}

variable "vpc_id" {
  description = "ID of the VPC to deploy into"
  type        = string
}

variable "subnet_id" {
  description = "ID of a public subnet with a route to an internet gateway"
  type        = string
}

variable "domain" {
  description = "Public domain for the SonarQube server, for example sonar.example.com"
  type        = string
}

variable "acme_email" {
  description = "Email address used for Let's Encrypt certificate registration and expiry notices"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Use a Graviton type with arm64 or an x86 type with x86_64"
  type        = string
  default     = "t4g.large"
}

variable "architecture" {
  description = "CPU architecture of the AMI, must match the instance type"
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be arm64 or x86_64."
  }
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach ports 80 and 443. Port 80 stays required for the ACME HTTP-01 challenge"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Size of the persistent data EBS volume in GiB, mounted at /var/lib/docker"
  type        = number
  default     = 50
}

variable "data_volume_snapshot_id" {
  description = "Optional EBS snapshot ID to restore the data volume from"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID. When set, an A record for var.domain is created pointing to the Elastic IP"
  type        = string
  default     = null
}

variable "create_backup_bucket" {
  description = "Whether to create an S3 bucket for daily pg_dump backups"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Name of the backup bucket. Defaults to <name>-backups-<account_id>"
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Days to keep pg_dump backups in S3 before expiry"
  type        = number
  default     = 30
}

variable "enable_dlm_snapshots" {
  description = "Whether to create daily EBS snapshots of the data volume via Data Lifecycle Manager"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Number of daily EBS snapshots to retain"
  type        = number
  default     = 7
}

variable "enable_cloudwatch_alarms" {
  description = "Whether to create CPU and disk usage alarms and install the CloudWatch agent"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "ARNs notified by the optional CloudWatch alarms, for example an SNS topic"
  type        = list(string)
  default     = []
}

variable "sonarqube_image" {
  description = "SonarQube container image. Pin to an exact patch release in production"
  type        = string
  default     = "sonarqube:2026-lta-community"
}

variable "db_user" {
  description = "PostgreSQL user for SonarQube"
  type        = string
  default     = "sonar"
}

variable "db_name" {
  description = "PostgreSQL database name for SonarQube"
  type        = string
  default     = "sonar"
}

variable "compose_version" {
  description = "Pinned Docker Compose plugin release installed on the instance"
  type        = string
  default     = "v2.32.4"
}

variable "extra_env" {
  description = "Additional environment variables rendered into the instance .env file, for example JVM sizing overrides"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

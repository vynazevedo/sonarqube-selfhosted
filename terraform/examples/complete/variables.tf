variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "domain" {
  description = "Public domain for the SonarQube server, for example sonar.example.com"
  type        = string
}

variable "acme_email" {
  description = "Email address for Let's Encrypt registration"
  type        = string
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID for automatic DNS. Leave null to point DNS manually at the output public_ip"
  type        = string
  default     = null
}

variable "enable_cloudwatch_alarms" {
  description = "Enable infrastructure, application and backup health alarms"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "data_volume_snapshot_id" {
  description = "Optional data snapshot to restore (retain the original DB password in SSM/state)"
  type        = string
  default     = null
}

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

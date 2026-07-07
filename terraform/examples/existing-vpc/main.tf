terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "sonarqube" {
  source = "../.."

  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id
  domain          = var.domain
  acme_email      = var.acme_email
  route53_zone_id = var.route53_zone_id
}

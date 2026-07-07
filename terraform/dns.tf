resource "aws_route53_record" "this" {
  count = var.route53_zone_id != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.this.public_ip]
}

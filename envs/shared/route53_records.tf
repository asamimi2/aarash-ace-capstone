resource "aws_route53_record" "prod_app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "app.prod.internal.capstone.com"
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.prod.outputs.alb_dns_name]
}

resource "aws_route53_record" "dev_app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "app.dev.internal.capstone.com"
  type    = "A"
  ttl     = 60
  records = [data.terraform_remote_state.dev.outputs.dev_private_ip]
}

# Public name for your Prod app
resource "aws_route53_record" "prod_public_app" {
  zone_id = aws_route53_zone.public_capstone.zone_id   # <-- resource, not data
  name    = "app.capstone.partipilotesting.com"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.prod.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.prod.outputs.alb_zone_id
    evaluate_target_health = true
  }
}
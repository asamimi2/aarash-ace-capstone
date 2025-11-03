data "terraform_remote_state" "prod" {
  backend = "local"
  config  = { path = "../prod/terraform.tfstate" }
}
data "terraform_remote_state" "dev" {
  backend = "local"
  config  = { path = "../dev/terraform.tfstate" }
}

# (If you already have the dns-anchor VPC, reuse it and delete this block)
resource "aws_vpc" "dns_anchor" {
  cidr_block           = "10.253.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "dns-anchor" }
}

# Create the Private Hosted Zone in Shared and attach it to the anchor VPC
resource "aws_route53_zone" "internal" {
  name = "internal.capstone.com"          # <-- change to your internal domain
  vpc  { vpc_id = aws_vpc.dns_anchor.id }  # first association must be in the zone's account
  comment = "Central PHZ in Shared"
}

# Authorize Dev and Prod VPCs to associate
resource "aws_route53_vpc_association_authorization" "dev_auth" {
  zone_id    = aws_route53_zone.internal.zone_id
  vpc_id     = data.terraform_remote_state.dev.outputs.vpc_id
  vpc_region = "us-east-1"               # <-- match your VPC region
}

resource "aws_route53_vpc_association_authorization" "prod_auth" {
  zone_id    = aws_route53_zone.internal.zone_id
  vpc_id     = data.terraform_remote_state.prod.outputs.vpc_id
  vpc_region = "us-east-1"
}

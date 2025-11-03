# Look up existing public hosted zone (do NOT create a new one)
resource "aws_route53_zone" "public_capstone" {
  name         = "capstone.partipilotesting.com"
  comment = "Public zone for capstone.com"
}
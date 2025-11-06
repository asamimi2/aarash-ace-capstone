output "shared_internal_zone_id" {
  value = aws_route53_zone.internal.zone_id
}

output "public_zone_id" {
  value = aws_route53_zone.public_capstone.zone_id
}

output "public_ns" {
  value = aws_route53_zone.public_capstone.name_servers
}

output "internal_zone_name" {
  value = aws_route53_zone.internal.name
}

output "internal_zone_id" {
  value = aws_route53_zone.internal.zone_id
}

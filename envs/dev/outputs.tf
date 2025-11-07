output "dev_private_ip" {
  description = "Private IP of the Dev web instance"
  value       = aws_instance.dev_web.private_ip
}

output "dev_instance_id" {
  description = "Instance ID of the Dev web instance"
  value       = aws_instance.dev_web.id
}

output "vpc_id" {
  value = module.vpc.id
}

output "alb_dns_name" {
  value = aws_lb.dev_web.dns_name
}

output "alb_zone_id" {
  value = aws_lb.dev_web.zone_id
}

# (optional duplicates; keep if other stacks read these names)
output "dev_alb_dns" {
  value = aws_lb.dev_web.dns_name
}

output "dev_alb_zone_id" {
  value = aws_lb.dev_web.zone_id
}
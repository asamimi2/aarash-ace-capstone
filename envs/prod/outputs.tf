output "prod_public_ip" {
  description = "Public IP of the Prod web instance"
  value       = aws_instance.prod_web.public_ip
}

output "prod_private_ip" {
  description = "Private IP of the Prod web instance"
  value       = aws_instance.prod_web.private_ip
}

output "prod_instance_id" {
  description = "Instance ID of the Prod web instance"
  value       = aws_instance.prod_web.id
}

output "prod_alb_dns" {
  value = aws_lb.web.dns_name
}

output "vpc_id" {
  value = module.vpc.id
}

output "alb_dns_name" { 
  value = aws_lb.web.dns_name 
}

output "alb_zone_id"  { 
  value = aws_lb.web.zone_id
}

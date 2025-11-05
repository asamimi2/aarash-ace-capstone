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

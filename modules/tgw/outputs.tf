# modules/tgw/outputs.tf
output "tgw_id" {
  value = aws_ec2_transit_gateway.this.id
}

output "rt_ids" {
  value = { for k, v in aws_ec2_transit_gateway_route_table.rt : k => v.id }
}

output "tgw_arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.this.arn
}
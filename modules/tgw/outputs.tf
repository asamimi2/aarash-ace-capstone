output "tgw_id" {
  value       = aws_ec2_transit_gateway.this.id
  description = "Transit Gateway ID"
}

output "rt_ids" {
  value       = { for k, rt in aws_ec2_transit_gateway_route_table.rt : k => rt.id }
  description = "Map of TGW route table IDs (dev/prod/inspect/vpn)"
}
